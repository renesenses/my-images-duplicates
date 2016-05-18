use utf8;
package Images::Schema::Result::Image;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Images::Schema::Result::Image

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<image>

=cut

__PACKAGE__->table("image");

=head1 ACCESSORS

=head2 img_id

  data_type: 'text'
  is_nullable: 0

=head2 img_nbocc

  data_type: 'integer'
  default_value: 1
  is_nullable: 0

=head2 img_size

  data_type: 'integer'
  is_nullable: 0

=head2 img_mtime

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "img_id",
  { data_type => "text", is_nullable => 0 },
  "img_nbocc",
  { data_type => "integer", default_value => 1, is_nullable => 0 },
  "img_size",
  { data_type => "integer", is_nullable => 0 },
  "img_mtime",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</img_id>

=back

=cut

__PACKAGE__->set_primary_key("img_id");

=head1 RELATIONS

=head2 locations

Type: has_many

Related object: L<Images::Schema::Result::Location>

=cut

__PACKAGE__->has_many(
  "locations",
  "Images::Schema::Result::Location",
  { "foreign.loc_id" => "self.img_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07045 @ 2016-05-18 16:22:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YRozXXkAo5Zgm8iTXXLQow


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
