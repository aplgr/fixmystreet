package FixMyStreet::App::Form::Waste::Garden;

use utf8;
use HTML::FormHandler::Moose;
extends 'FixMyStreet::App::Form::Waste';

has_field service_id => ( type => 'Hidden' );

sub details_update_fields {
    my $form = shift;
    my $data = $form->saved_data;
    my $c = $form->{c};

    # From first question
    my $existing = $data->{existing_number} || 0;
    $existing = 0 if $data->{existing} eq 'no';

    # From main form
    my $current_bins = $c->get_param('current_bins') || $form->saved_data->{current_bins} || $existing;
    my $bin_count = $c->get_param('bins_wanted') || $form->saved_data->{bins_wanted} || $existing;
    my $new_bins = $bin_count - $current_bins;

    my $cost_pa = $bin_count == 0 ? 0 : $form->{c}->cobrand->garden_waste_cost_pa($bin_count);
    my $cost_now_admin = $form->{c}->cobrand->garden_waste_new_bin_admin_fee($new_bins);
    $c->stash->{cost_pa} = $cost_pa / 100;
    $c->stash->{cost_now_admin} = $cost_now_admin / 100;
    if ($data->{apply_discount}) {
        (
            $c->stash->{cost_pa},
            $c->stash->{cost_now_admin},
            $c->stash->{per_bin_cost},
            $c->stash->{per_new_bin_cost},
            $c->stash->{per_new_bin_first_cost},
            ) =
        $c->cobrand->apply_garden_waste_discount(
            $c->stash->{cost_pa},
            $c->stash->{cost_now_admin},
            $c->stash->{per_bin_cost},
            $c->stash->{per_new_bin_cost},
            $c->stash->{per_new_bin_first_cost},
            );
    }
    $c->stash->{cost_now} = $c->stash->{cost_now_admin} + $c->stash->{cost_pa};
    my $max_bins = $c->stash->{garden_form_data}->{max_bins};

    return {
        current_bins => { default => $existing, range_end => $max_bins },
        bins_wanted => { default => $bin_count, range_end => $max_bins },
    };
}

sub with_sacks_choice { 0 }

has_page intro => (
    title_ggw => 'Subscribe to the %s',
    template => 'waste/garden/subscribe_intro.html',
    fields => ['continue', 'apply_discount'],
    update_field_list => sub {
        my $form = shift;
        my $data = $form->saved_data;
        $data->{_garden_sacks} = 1 if $form->with_sacks_choice;
        return {};
    },
    field_ignore_list => sub {
        my $page = shift;
        my $c = $page->form->c;
        if (!($c->stash->{waste_features}->{ggw_discount_as_percent}) || !($c->stash->{is_staff})) {
            return ['apply_discount']
        }
    },
    next => sub {
        return 'choice' if $_[0]->{_garden_sacks};
        'existing';
    }
);

has_page existing => (
    title_ggw => 'Subscribe to the %s',
    template => 'waste/garden/subscribe_existing.html',
    fields => ['existing', 'existing_number', 'continue'],
    next => 'details',
);

has_page details => (
    title_ggw => 'Subscribe to the %s',
    template => 'waste/garden/subscribe_details.html',
    fields => ['current_bins', 'bins_wanted', 'payment_method', 'cheque_reference', 'name', 'email', 'phone', 'password', 'email_renewal_reminders', 'continue_review'],
    field_ignore_list => sub {
        my $page = shift;
        my $c = $page->form->c;
        my @fields;
        push @fields, 'email_renewal_reminders' if !$c->cobrand->garden_subscription_email_renew_reminder_opt_in;
        push @fields, 'password' if $c->stash->{staff_payments_allowed} or $c->cobrand->call_hook('waste_password_hidden');
        push @fields, ('payment_method', 'cheque_reference') if $c->stash->{staff_payments_allowed} && !$c->cobrand->waste_staff_choose_payment_method;
        return \@fields;
    },
    update_field_list => \&details_update_fields,
    next => 'summary',
);

has_page summary => (
    fields => ['tandc', 'submit'],
    title => 'Submit container request',
    template => 'waste/garden/subscribe_summary.html',
    update_field_list => sub {
        my $form = shift;
        my $data = $form->saved_data;
        my $c = $form->{c};

        # Might not have these fields (e.g. SLWP), so include defaults
        my $current_bins = $data->{current_bins} || 0;
        my $bin_count = $data->{bins_wanted} || 1;
        my $new_bins = $bin_count - $current_bins;
        my $cost_pa;
        if (($data->{container_choice}||'') eq 'sack') {
            $cost_pa = $c->cobrand->garden_waste_sacks_cost_pa() * $bin_count;
        } else {
            $cost_pa = $c->cobrand->garden_waste_cost_pa($bin_count);
        }
        my $cost_now_admin = $c->cobrand->garden_waste_new_bin_admin_fee($new_bins);
        if ($data->{apply_discount}) {
            ($cost_pa, $cost_now_admin) = $c->cobrand->apply_garden_waste_discount(
                $cost_pa, $cost_now_admin);
        }

        my $total = $cost_now_admin + $cost_pa;

        $data->{cost_now_admin} = $cost_now_admin / 100;
        $data->{cost_pa} = $cost_pa / 100;
        $data->{display_total} = $total / 100;

        my $button_text = 'Continue to payment';
        my $features = $c->cobrand->feature('waste_features');
        if ($c->stash->{is_staff} && $features->{text_for_waste_payment}) {
            $button_text = $features->{text_for_waste_payment};
        }
        return { submit => { value => $button_text }};
    },
    finished => sub {
        return $_[0]->wizard_finished('process_garden_data');
    },
    next => 'done',
);

has_page done => (
    title => 'Container request sent',
    template => 'waste/confirmation.html',
);

has_field existing => (
    type => 'Select',
    label => 'Do you already have one of these bins?',
    required => 1,
    tags => {
        hint => "For example, it may have been left at your house by the previous owner.",
    },
    widget => 'RadioGroup',
    options => [
        { value => 'yes', label => 'Yes', data_show => '#form-existing_number-row' },
        { value => 'no', label => 'No', data_hide => '#form-existing_number-row' },
    ],
);

has_field existing_number => (
    type => 'Integer',
    build_label_method => sub {
        my $self = shift;
        my $max_bins = $self->parent->{c}->stash->{garden_form_data}->{max_bins};
        return "How many? (1-$max_bins)";
    },
    validate_method => sub {
        my $self = shift;
        my $max_bins = $self->parent->{c}->stash->{garden_form_data}->{max_bins};
        if ( $self->parent->field('existing')->value eq 'yes' ) {
            $self->add_error('Please specify how many bins you already have')
                unless length $self->value;
            $self->add_error("Existing bin count must be between 1 and $max_bins")
                if $self->value < 1 || $self->value > $max_bins;
        } else {
            return 1;
        }
    },
);

has_field current_bins => (
    type => 'Integer',
    build_label_method => sub {
        my $self = shift;
        my $max_bins = $self->parent->{c}->stash->{garden_form_data}->{max_bins};
        return "Number of bins currently on site (0-$max_bins)";
    },
    required => 1,
    readonly => 1,
    range_start => 0,
);

sub bins_wanted_label_method {
    my ($self, $max_bins) = @_;
    $max_bins ||= $self->parent->{c}->stash->{garden_form_data}->{max_bins};
    return "Number of bins to be emptied (including bins already on site) (0-$max_bins)";
}

has_field bins_wanted => (
    type => 'Integer',
    build_label_method => \&bins_wanted_label_method,
    required => 1,
    range_start => 1,
    tags => {
        hint => 'We will deliver, or remove, bins if this is different from the number of bins already on the property',
    },
);

has_field apply_discount => (
    type => 'Checkbox',
    build_label_method => sub {
        my $self = shift;
        my $percent = $self->parent->{c}->stash->{waste_features}->{ggw_discount_as_percent};
        return "$percent" . '% Customer discount';
    },
    option_label => 'Check box if customer is entitled to a discount',
);

with 'FixMyStreet::App::Form::Waste::Billing';

has_field password => (
    type => 'Password',
    label => 'Password (optional)',
    tags => {
        hint => 'Choose a password to sign in and manage your account in the future. If you don’t pick a password, you will still be able to sign in by clicking a link in an email we send to you.',
    },
);

with 'FixMyStreet::App::Form::Waste::Garden::EmailRenewalReminders';

with 'FixMyStreet::App::Form::Waste::GardenTandC';

has_field continue => (
    type => 'Submit',
    value => 'Continue',
    element_attr => { class => 'govuk-button' },
    order => 999,
);

has_field continue_review => (
    type => 'Submit',
    value => 'Review subscription',
    element_attr => { class => 'govuk-button' },
);

has_field submit => (
    type => 'Submit',
    element_attr => { class => 'govuk-button' },
    order => 999,
);

sub validate {
    my $self = shift;
    $self->add_form_error('Please specify how many bins you already have')
        unless $self->field('existing')->is_inactive || $self->field('existing')->value eq 'no' || length $self->field('existing_number')->value;

    my $max_bins = $self->{c}->stash->{garden_form_data}->{max_bins};
    unless ( $self->field('current_bins')->is_inactive ) {
        my $total = $self->field('bins_wanted')->value;
        $self->add_form_error('The total number of bins cannot exceed ' . $max_bins)
            if $total > $max_bins;

        $self->add_form_error('The total number of bins must be at least 1')
            if $total == 0;
    }

    $self->next::method();
}

1;
