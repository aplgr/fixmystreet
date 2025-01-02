use utf8;
package FixMyStreet::DB::Result::Token;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->load_components(
  "FilterColumn",
  "+FixMyStreet::DB::JSONBColumn",
  "FixMyStreet::InflateColumn::DateTime",
  "FixMyStreet::EncodedColumn",
);
__PACKAGE__->table("token");
__PACKAGE__->add_columns(
  "scope",
  { data_type => "text", is_nullable => 0 },
  "token",
  { data_type => "text", is_nullable => 0 },
  "data",
  { data_type => "jsonb", is_nullable => 0 },
  "created",
  {
    data_type     => "timestamp",
    default_value => \"CURRENT_TIMESTAMP",
    is_nullable   => 0,
  },
);
__PACKAGE__->set_primary_key("scope", "token");


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2023-05-10 17:09:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:TWGVKx/pX+MC09UadeXWuw

use mySociety::AuthToken;

=head1 NAME

FixMyStreet::DB::Result::Token

=head2 DESCRIPTION

Representation of mySociety::AuthToken in the DBIx::Class world.

The 'data' value is automatically inflated and deflated in the same way that the
AuthToken would do it. 'token' is set to a new random value by default and the
'created' timestamp is achieved using the database function current_timestamp.

=cut

sub new {
    my ( $class, $attrs ) = @_;

    $attrs->{token}   ||= mySociety::AuthToken::random_token();
    $attrs->{created} ||= \'current_timestamp';

    my $new = $class->next::method($attrs);
    return $new;
}

sub redeemed {
    my $self = shift;
    return $self->data->{redeemed};
}

sub mark_redeemed {
    my ( $self, $epoch_seconds ) = @_;
    my $data = $self->data;
    $data->{redeemed} = $epoch_seconds;
    $self->update({ data => $data });
}

1;
