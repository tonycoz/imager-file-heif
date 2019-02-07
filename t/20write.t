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

done_testing();
