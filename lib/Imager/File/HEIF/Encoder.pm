package Imager::File::HEIF::Encoder;
use strict;
use warnings;

sub id {
    $_[0]{id};
}

sub name {
    $_[0]{name};
}

sub compression {
    $_[0]{compression};
}

sub supports_lossy_compression {
    $_[0]{supports_lossy_compression};
}

sub supports_lossless_compression {
    $_[0]{supports_lossless_compression};
}

sub parameters {
    @{$_[0]{parameters}};
}

1;
