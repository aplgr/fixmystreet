use utf8;
package FixMyStreet::DB::Result::ManifestTheme;

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
__PACKAGE__->table("manifest_theme");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "manifest_theme_id_seq",
  },
  "cobrand",
  { data_type => "text", is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "short_name",
  { data_type => "text", is_nullable => 0 },
  "background_colour",
  { data_type => "text", is_nullable => 1 },
  "theme_colour",
  { data_type => "text", is_nullable => 1 },
  "images",
  { data_type => "text[]", is_nullable => 1 },
  "wasteworks_name",
  { data_type => "text", is_nullable => 1 },
  "wasteworks_short_name",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("manifest_theme_cobrand_key", ["cobrand"]);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2023-11-20 12:04:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:bT9i4HHYfqs/4fo23OdZJg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
