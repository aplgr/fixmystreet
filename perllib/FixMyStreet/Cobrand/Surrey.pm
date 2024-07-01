package FixMyStreet::Cobrand::Surrey;
use parent 'FixMyStreet::Cobrand::Whitelabel';

use strict;
use warnings;

use FixMyStreet::Geocode::Address;

sub council_area_id { 2242 }
sub council_area { 'Surrey' }
sub council_name { 'Surrey County Council' }
sub council_url { 'surrey' }
sub is_two_tier { 1 }

sub disambiguate_location {
    my $self    = shift;
    my $string  = shift;

    return {
        %{ $self->SUPER::disambiguate_location() },
        centre => '51.2478663,-0.4205895',
        span   => '0.4000678,0.9071629',
        bounds => [ 51.0714965, -0.8489465, 51.4715643, 0.0582164 ],
        town => 'Surrey',

    };
}

=item * We include the C<external_id> (Zendesk reference) in the acknowledgement email.

=cut

sub report_sent_confirmation_email { 'external_id' }

=item * The default map view shows closed/fixed reports for 31 days

=cut

sub report_age {
    return {
        open => '90 days',
        closed => '31 days',
        fixed  => '31 days',
    };
}

=item * Add display_name as an extra contact field

=cut

sub contact_extra_fields { [ 'display_name' ] }

=item * We do not send alerts to report authors.

=cut

sub suppress_reporter_alerts { 1 }

=item * We do not send questionnaires.

=cut

sub send_questionnaires { 0 }

sub enter_postcode_text { 'Enter a nearby UK postcode, or street name and area' }

=item * The privacy policy is held on Surrey's own site

=cut

sub privacy_policy_url {
    return 'https://www.surreycc.gov.uk/council-and-democracy/your-privacy/our-privacy-notices/fixmystreet'
}

=head2 get_town

Returns the name of the town from the problem's geocode information, if present.

=cut

sub get_town {
    my ($self, $p) = @_;

    return unless $p->geocode;
    my $geocode = FixMyStreet::Geocode::Address->new($p->geocode);
    my $address = $geocode->{LPI} || $geocode->{address} || ($geocode->can('address') ? $geocode->address : '');
    return unless $address;
    my $town = $address->{town} || $address->{city} || $address->{TOWN_NAME} || $address->{locality} || $address->{village} || $address->{suburb};
    return $town;
}

=head2 dashboard_export_problems_add_columns

Surrey has an extra column in their stats export showing the number of subscribers to a report.
They are set up not to subscribe the original reporter to their own report so the alert number
is the number of users who have subscribed to the report for updates

=cut

sub dashboard_export_problems_add_columns {
    my ($self, $csv) = @_;

    $csv->add_csv_columns(
        alerts_count => "Subscribers",
    );

    my $alerts_lookup = $csv->dbi ? undef : $self->csv_update_alerts;

    $csv->csv_extra_data(sub {
        my $report = shift;

        if ($alerts_lookup) {
            return { alerts_count => ($alerts_lookup->{$report->id} || 0) };
        } else {
            return { alerts_count => ($report->{alerts_count} || 0) };
        }
    });
}

sub open311_config {
    my ($self, $row, $h, $params, $contact) = @_;

    $params->{multi_photos} = 1;
    $params->{upload_files} = 1;
}

sub open311_extra_data_include {
    my ($self, $row, $h) = @_;

    my $open311_only = [
        { name => 'fixmystreet_id',
          value => $row->id },
        { name => 'easting',
          value => $h->{easting} },
        { name => 'northing',
          value => $h->{northing} },
        { name => 'report_url',
          value => $h->{url} },
        { name => 'title',
          value => $row->title },
        { name => 'description',
          value => $row->detail },
        { name => 'category',
          value => $row->category },
        { name => 'group',
          value => $row->get_extra_metadata('group', '') },
    ];

    return $open311_only;
}

sub lookup_by_ref {
    my ($self, $ref) = @_;

    return [
          id => $ref,
          external_id => "Zendesk_" . $ref
      ];
}

1;
