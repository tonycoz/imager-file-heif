#!perl -w
use strict;
use Test::More;

use Imager::File::HEIF;
use Imager::Test qw(test_image is_image_similar);
use lib 't/lib';

{
  my $im = test_image;

  my $data;
  ok($im->write(data => \$data, type => "heif"),
     "write single image");
  ok(length $data, "actually wrote something");
  is(substr($data, 4, 8), 'ftypheic', "got a HEIC file");

  my $res = Imager->new;
  ok($res->read(data => \$data, type => "heif"),
     "read it back in again")
    or diag $res->errstr;
  is($res->getwidth, $im->getwidth, "check width");
  is($res->getheight, $im->getheight, "check height");
  is($res->getchannels, $im->getchannels, "check channels");
  is_image_similar($res, $im, 8_000_000, "check image matches roughly");
}

{
  my $im = test_image;
  my $im2 = $im->convert(preset => "gray")
    or diag $im->errstr;
  my $cmp = $im2->convert(preset => "rgb")
    or diag $im2->errstr;

  my $data;
  ok($im2->write(data => \$data, type => "heif"),
     "write single gray image")
    or diag $im2->errstr;
  ok(length $data, "actually wrote something (gray)");
  is(substr($data, 4, 8), 'ftypheic', "got a HEIC file");

  my $res = Imager->new;
  ok($res->read(data => \$data, type => "heif"),
     "read it back in again")
    or diag $res->errstr;
  is($res->getwidth, $cmp->getwidth, "check width");
  is($res->getheight, $cmp->getheight, "check height");
  is($res->getchannels, $cmp->getchannels, "check channels");
  is_image_similar($res, $cmp, 1_000_000, "check image matches roughly");
}

done_testing();
