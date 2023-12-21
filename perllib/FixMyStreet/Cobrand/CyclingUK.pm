package FixMyStreet::Cobrand::CyclingUK;
use base 'FixMyStreet::Cobrand::FixMyStreet';

use Moo;

=item path_to_web_templates

We want to use the fixmystreet.com templates as a fallback instead of
fixmystreet-uk-councils as this cobrand is effectively a reskin of .com rather
than a cobrand for a single council.

=cut

sub path_to_web_templates {
    my $self = shift;
    return [
        FixMyStreet->path_to( 'templates/web/cyclinguk' ),
        FixMyStreet->path_to( 'templates/web/fixmystreet.com' ),
    ];
}

sub privacy_policy_url { 'https://www.cyclinguk.org/privacy-policy' }

=item problems_restriction

This cobrand only shows reports made on it, not those from FMS.com or others.

=cut


sub problems_restriction {
    my ($self, $rs) = @_;

    my $table = ref $rs eq 'FixMyStreet::DB::ResultSet::Nearby' ? 'problem' : 'me';
    return $rs->search({
        "$table.cobrand" => "cyclinguk"
    });
}

=item problems_on_map_restriction

Same restriction on map as problems_restriction above.

=cut


sub problems_on_map_restriction {
    my ($self, $rs) = @_;
    $self->problems_restriction($rs);
}

sub updates_restriction {
    my ($self, $rs) = @_;
    return $rs->search({ 'problem.cobrand' => 'cyclinguk' }, { join => 'problem' });
}


=item allow_report_extra_fields

Enables the ReportExtraField feature which allows the addition of
site-wide extra questions when making reports. Used for the custom Cycling UK
questions when making reports.

=cut

sub allow_report_extra_fields { 1 }

sub admin_allow_user {
    my ( $self, $user ) = @_;
    return 1 if $user->is_superuser;
    return undef unless defined $user->from_body;
    # Make sure only Cycling UK staff can access admin
    return 1 if $user->from_body->name eq 'Cycling UK';
}

=item * Users with a cyclinguk.org email can always be found in the admin.

=cut

sub admin_user_domain { 'cyclinguk.org' }

=item users_restriction

Cycling UK staff can only see users who are also Cycling UK staff, or have a
cyclinguk.org email address, or who have sent a report or update using the
cyclinguk cobrand.

=cut

sub users_restriction { FixMyStreet::Cobrand::UKCouncils::users_restriction($_[0], $_[1]) }


=item dashboard_extra_bodies

Cycling UK dashboard should show all bodies that have received a report made
via the cobrand.

=cut

sub dashboard_extra_bodies {
    my ($self) = @_;

    my @results = FixMyStreet::DB->resultset('Problem')->search({
        cobrand => 'cyclinguk',
    }, {
        distinct => 1,
        columns => { bodies_str => \"regexp_split_to_table(bodies_str, ',')" }
    })->all;

    my @bodies = map { $_->bodies_str } @results;

    return FixMyStreet::DB->resultset('Body')->search(
        { 'id' => { -in => \@bodies } },
        { order_by => 'name' }
    )->active->all;
}

sub dashboard_default_body {};

=item get_body_sender

Reports made on the Cycling UK staging site should never be sent anywhere,
as we don't want to unexpectedly send Pro clients reports made as part of
Cycling UK's testing.

=cut

sub get_body_sender {
    my ( $self, $body, $problem ) = @_;

    return { method => 'Blackhole' } if FixMyStreet->config('STAGING_SITE');

    return $self->SUPER::get_body_sender($body, $problem);
}

sub get_body_handler_for_problem {
    my ( $self, $problem ) = @_;

    # want to force CyclingUK cobrand on staging so our get_body_sender is used
    # and reports aren't sent anywhere.
    return $self if FixMyStreet->config('STAGING_SITE');

    return $self->SUPER::get_body_handler_for_problem($problem);
}

=item dashboard_export_problems_add_columns

Reports made on the Cycling UK site have some extra questions shown to the
user - the answers to all of these are included in the CSV output.

=cut

sub dashboard_export_problems_add_columns {
    my ($self, $csv) = @_;

    $csv->add_csv_columns(
        injury_suffered => 'Injury suffered?',
        property_damage => 'Property damage?',
        transport_mode => 'Mode of transport',
        transport_other => 'Mode of transport (other)',
    );

    $csv->csv_extra_data(sub {
        my $report = shift;
        return {
            injury_suffered => $csv->_extra_field($report, 'CyclingUK_injury_suffered') || '',
            property_damage => $csv->_extra_field($report, 'CyclingUK_property_damage') || '',
            transport_mode => $csv->_extra_field($report, 'CyclingUK_transport_mode') || '',
            transport_other => $csv->_extra_field($report, 'CyclingUK_transport_other') || '',
        };
    });
}

1;
