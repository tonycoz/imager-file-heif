#!perl -w
use strict;
use Test::More;

use Imager::File::HEIF;
use Imager::Test qw(test_image is_image_similar);
use lib 't/lib';

for my $type (qw(heif avif)) {
  my $brand = $type eq "heif" ? "heic" : $type;
  {
    my $im = test_image;

    my $data;
    ok($im->write(data => \$data, type => $type),
       "$type: write single image");
    ok(length $data, "$type: actually wrote something");
    is(substr($data, 4, 8), "ftyp$brand", "$type: got a $type file");

    my $res = Imager->new;
    ok($res->read(data => \$data, type => $type),
       "$type: read it back in again")
      or diag $res->errstr;
    is($res->getwidth, $im->getwidth, "$type: check width");
    is($res->getheight, $im->getheight, "$type: check height");
    is($res->getchannels, $im->getchannels, "$type: check channels");
    is_image_similar($res, $im, 8_000_000, "$type: check image matches roughly");

    # lossless
    my $data2;
    ok($im->write(data => \$data2, type => $type, heif_lossless => 1),
       "$type: write in lossless mode");
    ok(length $data2, "$type: got some data");
    my $res2 = Imager->new;
    ok($res2->read(data => \$data2, type => $type),
       "$type: read it back in")
      or diag $res2->errstr;
    is_image_similar($res, $im, 8_000_000, "$type: check image matches roughly");
    # horribly enough, lossless is worse than lossy @80 quality
    note "type $type";
    note "quality lossy    ".Imager::i_img_diff($im->{IMG}, $res->{IMG});
    note "quality lossless ".Imager::i_img_diff($im->{IMG}, $res2->{IMG});
  }

  {
    my $im = test_image;
    my $im2 = $im->convert(preset => "gray")
      or diag $im->errstr;
    my $cmp = $im2->convert(preset => "rgb")
      or diag $im2->errstr;

    my $data;
    ok($im2->write(data => \$data, type => $type),
       "$type: write single gray image")
      or diag $im2->errstr;
    ok(length $data, "$type: actually wrote something (gray)");
    is(substr($data, 4, 8), "ftyp$brand", "$type: got a $type file");

    my $res = Imager->new;
    ok($res->read(data => \$data, type => $type),
       "$type: read it back in again")
      or diag $res->errstr;
    is($res->getwidth, $cmp->getwidth, "$type: check width");
    is($res->getheight, $cmp->getheight, "$type: check height");
    is($res->getchannels, $cmp->getchannels, "$type: check channels");
    is_image_similar($res, $cmp, 1_000_000, "$type: check image matches roughly");
  }

 SKIP:
  {
    my $cmp = Imager->new(xsize => 64, ysize => 64, channels => 4);
    $cmp->box(filled => 1, color => [ 255, 0, 0, 128 ], xmax => 31);
    $cmp->box(filled => 1, color => [ 0, 0, 255, 192 ], xmin => 32);
    $cmp->box(filled => 1, ymin => 50, color => [ 0, 255, 0, 64 ]);
    my $data;
    ok($cmp->write(data => \$data, type => $type),
       "$type: write alpha")
      or do { diag $cmp->errstr; skip "couldn't write alpha", 1; };
    my $res = Imager->new;
    ok($res->read(data => \$data, type => $type),
       "$type: read it back in")
      or do { diag $res->errstr; skip "couldn't read it back in", 1; };
    is($res->getwidth, $cmp->getwidth, "$type: check width");
    is($res->getheight, $cmp->getheight, "$type: check height");
    is($res->getchannels, $cmp->getchannels, "$type: check channels");
    is_image_similar($res, $cmp, 10_000, "$type: check image matches roughly");
  }

 SKIP:
  {
    my @cmp;
    push @cmp, test_image();
    push @cmp, test_image()->convert(preset => "gray");
    @cmp = ( (@cmp) x 3 );

    my $data;
    ok(Imager->write_multi({ type => $type, data => \$data }, @cmp),
       "$type: write multiple images")
      or diag(Imager->errstr);
    ok(length $data, "$type: it wrote something");

    my @res = Imager->read_multi(type => $type, data => \$data)
      or do { diag "couldn't read:" . Imager->errstr; skip "couldn't read", 1 };
    is(@res, @cmp, "$type: got the right number of images");
    for my $i ( 0 .. $#cmp) {
      my $cmp = $cmp[$i]->getchannels() == 3 ? $cmp[$i] : $cmp[$i]->convert(preset => "rgb");
      is_image_similar($res[$i], $cmp, 8_000_000,
                       "$type: check image $i");
    }
  }
}

done_testing();
