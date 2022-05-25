package Imager::File::AVIF;
use strict;
use warnings;

# load the magic
use Imager::File::HEIF;

our $VERSION = "0.003";

__END__

=head1 NAME

Imager::File::AVIF - read and write AVIF files

=head1 SYNOPSIS

  use Imager;
  # you need to explicitly load it, or supply a type => "avif" parameter
  use Imager::File::AVIF;

  my $img = Imager->new;
  $img->read(file=>"foo.avif")
    or die $img->errstr;

  # type won't be necessary if the extension is avif from Imager 1.008
  $img->write(file => "foo.avif", type => "avif")
    or die $img->errstr;

=head1 DESCRIPTION

Implements .avif file support for Imager.

=head1 CONTROLLING COMPRESSION

You can control compression through two tags (implicityly set on the
images via write() or write_multi()):

=over

=item *

C<avif_lossless> - if this is non-zero the image is compressed in
"lossless" mode.  Note that in both lossy and lossless modes the image
is converted from the RGB colorspace to the YCbCr colorspace, which
will lose information.  If non-zero the C<avif_quality> value is
ignored (and irrelevant.)  Default: 0 (lossy compression is used.)

=item *

C<avif_quality> - a value from 0 to 100 representing the quality of
lossy compression.  Default: 80.

=back

B<WARNING>: from my testing, using the rough measure done by Imager
i_img_diff(), lossy at 80 quality turned out closer to the original
image than lossless.

=head1 AUTHOR

Tony Cook <tonyc@cpan.org>

=head1 SEE ALSO

L<Imager>, L<Imager::Files>, L<Imager::File::HEIF>.

=cut
