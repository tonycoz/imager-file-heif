#!perl -w
use strict;
use Test::More;

use Imager::File::HEIF;
use Imager::Test qw(test_image is_image_similar);
use lib 't/lib';

{
  my $cmp = test_image;

  my $im = Imager->new;
  ok($im->read(file => "testimg/simple.heic", type => "heif"),
     "read single image");
  is($im->getwidth, $cmp->getwidth, "check width");
  is($im->getheight, $cmp->getheight, "check height");
  is_image_similar($im, $cmp, 10_000_000, "check if vaguely similar");
}

done_testing();
