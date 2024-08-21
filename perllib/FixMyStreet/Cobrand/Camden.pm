=head1 NAME

FixMyStreet::Cobrand::Camden - code specific to the Camden cobrand

=head1 SYNOPSIS

Camden is a London borough using FMS with a Symology integration

=cut


package FixMyStreet::Cobrand::Camden;
use parent 'FixMyStreet::Cobrand::Whitelabel';

use strict;
use warnings;

use constant BRENT_MAPIT_ID => 2488;
use constant BARNET_MAPIT_ID => 2489;
use constant WESTMINSTER_MAPIT_ID => 2504;
use constant ISLINGTON_MAPIT_ID => 2507;
use constant HARINGEY_MAPIT_ID => 2509;
use constant CITY_MAPIT_ID => 2512;

sub council_area_id { return [2505, BRENT_MAPIT_ID, BARNET_MAPIT_ID, WESTMINSTER_MAPIT_ID, ISLINGTON_MAPIT_ID, HARINGEY_MAPIT_ID, CITY_MAPIT_ID]; }
sub council_area { return 'Camden'; }
sub council_name { return 'Camden Council'; }
sub council_url { return 'camden'; }
sub get_geocoder { 'OSM' }
sub cut_off_date { '2023-02-01' }

sub enter_postcode_text { 'Enter a Camden postcode or street name' }

sub disambiguate_location {
    my $self    = shift;
    my $string  = shift;

    my $town = 'Camden';

    return {
        %{ $self->SUPER::disambiguate_location() },
        town   => $town,
        centre => '51.546390811297,-0.157422262955539',
        span   => '0.0603011959324533,0.108195286339115',
        bounds => [ 51.5126591342049, -0.213511484504216, 51.5729603301373, -0.105316198165101 ],
    };
}

sub new_report_title_field_label {
    "Location of the problem"
}

sub new_report_title_field_hint {
    "e.g. outside no.18, or near postbox"
}

sub send_questionnaires {
    return 0;
}

sub privacy_policy_url {
    'https://www.camden.gov.uk/data-protection-privacy-and-cookies'
}

sub admin_user_domain { 'camden.gov.uk' }

sub lookup_site_code_config {
    my ($self, $property) = @_;

    # uncoverable subroutine
    # uncoverable statement
    {
        buffer => 1000, # metres
        url => "https://tilma.mysociety.org/mapserver/camden",
        srsname => "urn:ogc:def:crs:EPSG::27700",
        typename => "Streets",
        property => $property,
        accept_feature => sub { 1 },
    }
}

sub open311_update_missing_data {
    my ($self, $row, $h, $contact) = @_;

    # Reports made via the app probably won't have a NSGRef because we don't
    # display the road layer. Instead we'll look up the closest asset from the
    # WFS service at the point we're sending the report over Open311.
    if (!$row->get_extra_field_value('NSGRef')) {
        if (my $ref = $self->lookup_site_code($row, 'NSG_REF')) {
            $row->update_extra_field({ name => 'NSGRef', description => 'NSG Ref', value => $ref });
        }
    }
}

sub open311_config {
    my ($self, $row, $h, $params, $contact) = @_;
    $params->{multi_photos} = 1;
}

sub open311_munge_update_params {
    my ($self, $params, $comment, $body) = @_;
    $params->{service_request_id_ext} = $comment->problem->id;

    my $contact = $comment->problem->contact;
    $params->{service_code} = $contact->email;
}

=head2 should_skip_sending_update

If we fail a couple of times to send an update, stop trying.

=cut

sub should_skip_sending_update {
    my ($self, $comment) = @_;
    return 1 if $comment->send_fail_count >= 2 && $comment->send_fail_reason =~ /Username required for notification/;
}

=head2 categories_restriction

Camden don't want TfL's River Piers categories on their cobrand.

=cut

sub categories_restriction {
    my ($self, $rs) = @_;

    return $rs->search( { 'me.category' => { -not_like => 'River Piers%' } } );
}

# Problems and comments are always treated as anonymous so the user's name isn't displayed.
sub is_problem_anonymous { 1 }

sub is_comment_anonymous { 1 }

sub social_auth_enabled {
    my $self = shift;

    return $self->feature('oidc_login') ? 1 : 0;
}

sub user_from_oidc {
    my ($self, $payload) = @_;

    # Extract the user's name and email address from the payload.
    my $name = $payload->{name};
    my $email = $payload->{preferred_username};

    return ($name, $email);
}

=head2 check_report_is_on_cobrand_asset

If the location is covered by an area of differing responsibility (e.g. Brent
in Camden, or Camden in Brent), return true (either 1 if an area name is
provided, or the name of the area if not).

=cut

sub check_report_is_on_cobrand_asset {
    my ($self, $council_area) = shift @_;

    my $lat = $self->{c}->stash->{latitude};
    my $lon = $self->{c}->stash->{longitude};
    my ($x, $y) = Utils::convert_latlon_to_en($lat, $lon, 'G');
    my $host = FixMyStreet->config('STAGING_SITE') ? "tilma.staging.mysociety.org" : "tilma.mysociety.org";

    my $cfg = {
        url => "https://$host/mapserver/camden",
        srsname => "urn:ogc:def:crs:EPSG::27700",
        typename => "AgreementBoundaries",
        filter => "<Filter><Contains><PropertyName>Geometry</PropertyName><gml:Point><gml:coordinates>$x,$y</gml:coordinates></gml:Point></Contains></Filter>",
        outputformat => 'GML3',
    };

    my $features = $self->_fetch_features($cfg, $x, $y, 1);

    if ($$features[0]) {
        if ($council_area) {
            if ($$features[0]->{'ms:AgreementBoundaries'}->{'ms:RESPBOROUG'} eq $council_area) {
                return 1;
            }
        } else {
            return $$features[0]->{'ms:AgreementBoundaries'}->{'ms:RESPBOROUG'};
        }
    }
}

=head2 munge_overlapping_asset_bodies

Alters the list of available bodies for the location,
depending on calculated responsibility. Here, we remove
any other council bodies if we're inside Camden or on the
Camden boundaries layer.

=cut

sub munge_overlapping_asset_bodies {
    my ($self, $bodies) = @_;

    # in_area will be true if the point is within the administrative area of Camden
    my $in_area = grep ($self->council_area_id->[0] == $_, keys %{$self->{c}->stash->{all_areas}});
    # cobrand will be true if the point is within an area of different responsibility from the norm
    my $cobrand = $self->check_report_is_on_cobrand_asset;

    if ($in_area) {
        if ($in_area && !$cobrand) {
            # Within Camden, and Camden's responsibility
            %$bodies = map { $_->id => $_ } grep {
                $_->name ne 'Brent Council' &&
                $_->name ne 'Barnet Borough Council' &&
                $_->name ne 'Westminster City Council' &&
                $_->name ne 'Islington Borough Council' &&
                $_->name ne 'Haringey Borough Council' &&
                $_->name ne 'City of London Corporation'
                } values %$bodies;
        } else {
            # ...read from the asset layer whose responsibility it is and keep them and TfL and National Highways
            my $selected = &_boundary_councils->{$cobrand};
            %$bodies = map { $_->id => $_ } grep {
                $_->name eq $selected || $_->name eq 'TfL' || $_->name eq 'National Highways'
            } values %$bodies;
        }
    } else {
        # Not in the area of Camden...
        if (!$cobrand || $cobrand ne 'LB Camden') {
            # ...not Camden's responsibility - remove Camden
            %$bodies = map { $_->id => $_ } grep {
                $_->name ne 'Camden Borough Council'
                } values %$bodies;
        } else {
            # ...Camden's responsibility - leave bodies alone
        }
    }
};

=head2 dashboard_export_problems_add_columns

Has user name and email fields added to their csv export

=cut

sub dashboard_export_problems_add_columns {
    my ($self, $csv) = @_;

    $csv->add_csv_columns(
        name => 'User Name',
        user_email => 'User Email',
    );

    $csv->objects_attrs({
        '+columns' => ['user.email'],
        join => 'user',
    });

    return if $csv->dbi; # Already covered

    $csv->csv_extra_data(sub {
        my $report = shift;

        return {
            name => $report->name || '',
            user_email => $report->user ? $report->user->email : '',
        };
    });
}

=head2 post_report_sent

Camden auto-closes its abandoned bike/scooter categories,
with an update with explanatory text added.

=cut

sub post_report_sent {
    my ($self, $problem) = @_;

    my $contact = $problem->contact;
    my %groups = map { $_ => 1 } @{ $contact->groups };

    if ($groups{'Hired e-bike or e-scooter'}) {
        $self->_post_report_sent_close($problem, 'report/new/close_bike.html');
    }
}

sub _boundary_councils {
    return {
        'LB Brent' => 'Brent Council',
        'LB Barnet' => 'Barnet Borough Council',
        'LB Camden' => 'Camden Borough Council',
        'LB Westminster' => 'Westminster City Council',
        'LB Islington' => 'Islington Borough Council',
        'LB Haringey' => 'Haringey Borough Council',
        'City Of London' => 'City of London Corporation',
        'TfL' => 'Transport for London',
    }
}

1;
