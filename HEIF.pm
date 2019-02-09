package Imager::File::HEIF;
use strict;
use Imager;
use vars qw($VERSION @ISA);

BEGIN {
  $VERSION = "0.001";

  require XSLoader;
  XSLoader::load('Imager::File::HEIF', $VERSION);
}

Imager->register_reader
  (
   type=>'heif',
   single => 
   sub { 
     my ($im, $io, %hsh) = @_;

     my $page = $hsh{page};
     defined $page or $page = 0;
     $im->{IMG} = i_readheif($io, $page);

     unless ($im->{IMG}) {
       $im->_set_error(Imager->_error_as_msg);
       return;
     }

     return $im;
   },
   multiple =>
   sub {
     my ($io, %hsh) = @_;

     my @imgs = i_readheif_multi($io);
     unless (@imgs) {
       Imager->_set_error(Imager->_error_as_msg);
       return;
     }

     return map bless({ IMG => $_, ERRSTR => undef }, "Imager"), @imgs;
   },
  );

Imager->register_writer
  (
   type=>'heif',
   single => 
   sub { 
     my ($im, $io, %hsh) = @_;

     $im->_set_opts(\%hsh, "i_", $im);
     $im->_set_opts(\%hsh, "heif_", $im);

     unless (i_writeheif($im->{IMG}, $io)) {
       $im->_set_error(Imager->_error_as_msg);
       return;
     }
     return $im;
   },
   multiple =>
   sub {
     my ($class, $io, $opts, @ims) = @_;

     Imager->_set_opts($opts, "heif_", @ims);

     my @work = map $_->{IMG}, @ims;
     my $result = i_writeheif_multi($io, @work);
     unless ($result) {
       $class->_set_error($class->_error_as_msg);
       return;
     }

     return 1;
   },
  );

eval {
  # available in some future version of Imager
  Imager->add_file_magic
    (
     name => "heif",
     bits => "    ftypheic",
     mask => "    xxxxxxxx",
    );
};

1;


__END__

=head1 NAME

Imager::File::HEIF - read and write HEIF files

=head1 SYNOPSIS

  use Imager;

  my $img = Imager->new;
  $img->read(file=>"foo.heif")
    or die $img->errstr;

  # type won't be necessary if the extension is heif from Imager 1.008
  $img->write(file => "foo.heif", type => "heif")
    or die $img->errstr;

=head1 DESCRIPTION

Implements .heif file support for Imager.

Due to the limitations of C<heif> (or possibly C<libheif>) grayscale
images are written as RGB images.
images are written as RGB images. FIXME: they're currently rejected.

libx265 will
L<reject|https://mailman.videolan.org/pipermail/x265-devel/2018-May/012068.html>
attempts to write images smaller than 64x64 pixels.  Since this may
change in the future I haven't tried to prevent that in Imager itself.

=head1 INSTALLATION

To install Imager::File::HEIF you need Imager installed and you need
libheif, libde265 and libx265 and their development files.

=head1 TODO

=over

=item *

can we hack grayscale by setting the chroma bits to zero?  The sample
code produces a chroma bits 8 image when given a grayscale input PNG,
which is why I suspect the format doesn't support gray, but they might
be a deficiency in the tool.

=item *

10-bit/sample and 12-bit/sample images.

=item *

writing alpha

=item *

writing grayscale (probably as RGB)

=item *

reading multiple images

=item *

reading metadata (any to read?) I think pixel ratios are available.

=item *

writing metadata.  We don't seem to have the animation metadata that
webp does.

=item *

reading sub-image data?  we can probably skip thumbs (or provide an
option to read the thumb rather than the main image), but are there
other images to read?  Low priority.

=item *

writing sub-image data?  Very low priority.

=item *

Everything else.

=back

=head1 AUTHOR

Tony Cook <tonyc@cpan.org>

=head1 SEE ALSO

Imager, Imager::Files.

=cut
