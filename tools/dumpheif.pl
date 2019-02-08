#!perl
use strict;
use warnings;

my $file = shift
  or die "Usage: $0 filename\n";

open my $fh, "<", $file
  or die "Cannot open file $file: $!\n";
binmode $fh;

do_dump($fh, "");

sub do_dump {
  my ($fh, $p) = @_;
  
  my $chead;
  while (read($fh, $chead, 8) == 8) {
    my ($size, $type) = unpack("L>a4", $chead);
    my $hsize = 8;
    if ($size == 1) {
      my $csize;
      if (read($fh, $csize, 8) == 8) {
	$size = unpack("Q>", $csize);
	$hsize += 8;
      }
      else {
	die "Failed to read 64-bit size\n";
      }
    }
    print "${p}Type $type size $size\n";
    my $body;
    if (read($fh, $body, $size-$hsize) != $size - $hsize) {
      die "Couldn't read body\n";
    }
    if ($type eq 'ftyp') {
      my ($maj_brand, $version, @min_brand) =
	unpack("a4L>(a4)*", $body);
      print "$p  Major brand: $maj_brand\n";
      print "$p  Version $version\n";
      print "$p  Minor brands: @min_brand\n";
    }
    elsif ($type eq 'meta') {
      dump_full_box($body, "$p  ");
    }
    elsif ($type =~ /^(ipco|iprp)$/) {
      open my $fh1, "<:raw", \$body or die;
      do_dump($fh1, "$p  ");
    }
    elsif ($type eq 'ispe') {
      my ($fh, $w, $h) = unpack("a4L>L>", $body);
      dump_full_box_hdr($fh, "$p  ");
      print "${p}  Width: $w\n";
      print "${p}  Height: $h\n";
    }
    elsif ($type eq 'iloc') {
      my ($version, $flags) = dump_full_box_hdr($body, "$p  ");
      substr($body, 0, 4, '');
      my $sizes = substr($body, 0, 2, '');
      my $off_sz = ord($sizes) >> 4;
      my $len_sz = ord($sizes) & 0xf;
      my $base_off_sz = ord(substr($sizes, 1)) >> 4;
      my $ind_sz_res = ord(substr($sizes, 1)) & 0xf;
      print "$p  Offset size: $off_sz\n";
      print "$p  Length size: $len_sz\n";
      print "$p  Base Offset size: $base_off_sz\n";
      if ($version == 1 || $version == 2) {
	print "$p  Index size: $ind_sz_res\n";
      }
      else {
	print "$p  Reserved: $ind_sz_res\n";
      }
      my $item_count;
      if ($version < 2) {
	$item_count = unpack("S>", substr($body, 0, 2, ''));
      }
      else {
	$item_count = unpack("L>", substr($body, 0, 2, ''));
      }
      print "$p  Item count: $item_count\n";
      for my $i (1 .. $item_count) {
	my $id;
	if ($version < 2) {
	  $id = unpack("S>", substr($body, 0, 2, ''));
	}
	else {
	  $id = unpack("L>", substr($body, 0, 4, ''));
	}
	print "$p    Item $id\n";
	if ($version == 1 || $version == 2) {
	  my ($cons) = unpack("S>", substr($body, 0, 2, ''));
	  print "$p      Reserved: ", $cons >> 4, "\n";
	  print "$p      Construction Method: ", $cons & 0xf, "\n";
	}
	my $data_ref_index = unpack("S>", substr($body, 0, 2, ''));
	print "$p      Data reference index: $data_ref_index\n";
	my $base_off;
	if ($base_off_sz == 4) {
	  $base_off = unpack("L>", substr($body, 0, 4, ''));
	}
	elsif ($base_off_sz == 2) {
	  $base_off = unpack("S>", substr($body, 0, 2, ''));
	}
	else {
	  $base_off = "Unhandled base offset size $base_off_sz";
	}
	print "$p      Base offset: $data_ref_index\n";

      }
    }
    # hvcC is referred to 14496-15 which isn't free
    else {
      my $lines = 0;
      while (length $body && $lines++ < 8) {
	print "${p}  ", unpack("H*", substr($body, 0, 16, "")), "\n";
      }
      print "${p}  ...\n" if length $body;
    }
  }
}

sub dump_full_box_hdr {
  my ($body, $p) = @_;

  my ($v, $cflags) = unpack("Ca3", $body);
  my $flags = unpack("L>", "$cflags\0");
  print "${p}Version: $v\n";
  printf "${p}Flags: %x\n", $flags;
  return ($v, $flags);
}

sub dump_full_box {
  my ($pbody, $p) = @_;
  open my $fh, "<:raw", \$pbody or die;
  my $full_head;
  read($fh, $full_head, 4) == 4 or die;
  my ($v, $cflags) = unpack("Ca3", $full_head);
  my $flags = unpack("L>", "$cflags\0");
  print "${p}Version: $v\n";
  printf "${p}Flags: %x\n", $flags;
  $p .= "  ";

  do_dump($fh, $p);
}
