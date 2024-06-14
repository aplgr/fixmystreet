use FixMyStreet::TestMech;
use FixMyStreet::Script::Reports;

my $mech = FixMyStreet::TestMech->new;

use_ok 'FixMyStreet::Cobrand::Surrey';

my $surrey = $mech->create_body_ok(2242, 'Surrey County Council', {}, { cobrand => 'surrey' });
my $surrey_staff_user = $mech->create_user_ok( 'staff@example.com', name => 'Staff User', from_body => $surrey );
$mech->create_contact_ok(body_id => $surrey->id, category => 'Potholes', email => 'potholes@example.org');
(my $report) = $mech->create_problems_for_body(1, $surrey->id, 'Pothole', {
            category => 'Potholes', cobrand => 'surrey',
            latitude => 51.293415, longitude => -0.441269, areas => '2242',
        });

FixMyStreet::override_config {
    ALLOWED_COBRANDS => [ 'surrey' ],
    MAPIT_URL => 'http://mapit.uk/',
}, sub {
        subtest 'CSV has Subscribers column populated by "alerts" registered on problem' => sub {
            $mech->log_in_ok($surrey_staff_user->email);
            $mech->get_ok("/dashboard?export=1");
            $mech->content_contains('"Site Used","Reported As",Subscribers', 'CSV content contains "Subscribers" column');
            $mech->content_contains('website,surrey,,0', 'CSV has 0 subscribers to report as reporter is not subscribed');
            $mech->log_out_ok;
            for my $update (
                {
                    name => 'John Groats',
                    email => 'notify@example.org',
                    text => 'Still there',
                    update_no => 1,
                },
                {
                    name => 'Joan Smith',
                    email => 'tome@example.org',
                    text => 'And still there',
                    update_no => 2,
                }
            ) {
                $mech->get_ok('/report/' . $report->id);
                $mech->submit_form_ok({ with_fields => {update => $update->{text}, name => $update->{name}, username_register => $update->{email}} });
                FixMyStreet::Script::Reports::send();
                my @emails = $mech->get_email;
                my $link = $mech->get_link_from_email($emails[0]); # Most recent email to confirm update
                $mech->get_ok( $link );
                $mech->log_in_ok($surrey_staff_user->email);
                $mech->get_ok("/dashboard?export=1");
                $mech->content_contains('website,surrey,,' . $update->{update_no}, 'CSV Subscriber number is ' . $update->{update_no});
                $mech->log_out_ok;
                $mech->clear_emails_ok;
            }
        }
};

done_testing();
