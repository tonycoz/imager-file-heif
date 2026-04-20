package Imager::File::HEIF::Encoder::Parameter;
use strict;
use warnings;

sub name {
    $_[0]{name};
}

sub default {
    $_[0]{default};
}

sub type {
    $_[0]{type};
}

sub minimum {
    $_[0]{minimum};
}

sub maximum {
    $_[0]{maximum};
}

sub values {
    @{$_[0]{values} || []};
}

1;
