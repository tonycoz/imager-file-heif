#!perl -w
use strict;
use ExtUtils::MakeMaker;
use Getopt::Long;
use Config;

my $verbose = $ENV{IM_VERBOSE};
my @libpaths;
my @incpaths;

GetOptions("incpath=s", \@incpaths,
           "libpath=s" => \@libpaths,
           "verbose|v" => \$verbose);

our $BUILDING_IMAGER;
our %IMAGER_LIBS;

my %opts = 
  (
   NAME => 'Imager::File::HEIF',
   VERSION_FROM => 'HEIF.pm',
   OBJECT => 'HEIF.o imheif.o',
   #DEFINE => $define,
   clean => { FILES => 'testout' },
  );

if (eval { ExtUtils::MakeMaker->VERSION('6.46'); 1 }) {
  $opts{LICENSE} = "perl_5";
  $opts{AUTHOR} = 'Tony Cook <tonyc@cpan.org>';
  $opts{ABSTRACT} = 'HEIF image file support for Imager';
  $opts{META_MERGE} =
    {
     'meta-spec' =>
     {
      version => "2",
      url => "https://metacpan.org/pod/CPAN::Meta::Spec",
     },
     resources =>
     {
      homepage => "http://imager.perl.org/",
      repository =>
      {
       type => "git",
       url => "git://github.com/tonycoz/imager-file-heif.git",
       web => "http://github.com/tonycoz/imager-file-heif.git",
      },
      bugtracker =>
      {
       web => "http://rt.cpan.org/NoAuth/Bugs.html?Dist=Imager-File-HEIF",
       mailto => 'bug-Imager-File-HEIF@rt.cpan.org',
      },
     },
    };
}

my @inc;
  unshift @INC, "inc";
  require Imager::ExtUtils;
  push @inc, Imager::ExtUtils->includes;
  $opts{TYPEMAPS} = [ Imager::ExtUtils->typemap ];

  # Imager required configure through use
  my @Imager_req = ( Imager => "0.94" );
  if (eval { ExtUtils::MakeMaker->VERSION('6.46'); 1 }) {
    $opts{META_MERGE}{prereqs} =
      {
       configure =>
       {
	requires =>
	{
	 @Imager_req,
	},
       },
       build =>
       {
	requires =>
	{
	 @Imager_req,
	 "Test::More" => "0.47",
	}
       },
       runtime =>
       {
	requires =>
	{
	 @Imager_req,
	}
       },
       test =>
       {
	requires =>
	{
	 "Test::More" => "0.47",
	}
       },
      };
    $opts{PREREQ_PM} =
      {
       @Imager_req,
       XSLoader => 0,
      };
  }

require Imager::Probe;

my %probe =
  (
   name => "HEIF",
   inccheck => sub { -e File::Spec->catfile($_[0], "libheif/heif.h") },
   libbase => [ "libheif", "libde265" ],
   testcode => _heif_test_code(),
   testcodeheaders => [ "libheif/heif.h", "stdio.h", "string.h" ],
   libopts => "-lheif -lde265",
   incpath => \@incpaths,
   libpath => \@libpaths,
   verbose => $verbose,
   pkg => [ "libheif" ],
  );

my $probe_res = Imager::Probe->probe(\%probe);
if ($probe_res) {
  push @inc, $probe_res->{INC};
  $opts{LIBS} = $probe_res->{LIBS};
  $opts{DEFINE} .= " $probe_res->{DEFINE}";
  $opts{INC} = "@inc";

  WriteMakefile(%opts);
}
else {
  die "OS unsupported: libheif libraries or headers not found\n";
}

sub _heif_test_code {
  return <<'CODE';
    uint32_t ver = heif_get_version_number();
    printf("libheif %d.%d.%d (%x)\n",
	    ver >> 24, (ver >> 16) & 0xFF, (ver >> 8) & 0xFF, ver);
    return 0;
CODE
}
