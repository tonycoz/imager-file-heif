#!perl -w
use strict;
use Test::More;

use Imager::File::HEIF;
use Imager::Test qw(test_image);
use lib 't/lib';

{
  my $im = test_image;

  my $data;
  ok($im->write(data => \$data, type => "heif"),
     "write single image");
  ok(length $data, "actually wrote something");
  is(substr($data, 4, 8), 'ftypheic', "got a HEIC file");
}

{
  my $im = test_image;
  my $im2 = $im->convert(preset => "gray")
    or diag $im->errstr;

  my $data;
  ok($im2->write(data => \$data, type => "heif"),
     "write single gray image")
    or diag $im2->errstr;
  ok(length $data, "actually wrote something (gray)");
  is(substr($data, 4, 8), 'ftypheic', "got a HEIC file");
}

done_testing();
