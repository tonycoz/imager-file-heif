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

=head1 INSTALLATION

To install Imager::File::HEIF you need Imager installed and you need
libheif and libde265.

=head1 TODO

Everything.

=head1 AUTHOR

Tony Cook <tonyc@cpan.org>

=head1 SEE ALSO

Imager, Imager::Files.

=cut
