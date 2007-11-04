#!/usr/bin/perl -w
use strict;

use Test::More tests => 2;
use WWW::UsePerl::Journal;

{
    my $j = WWW::UsePerl::Journal->new('russell');
    SKIP: {
        skip 'WUJERR: user not found', 2    unless($j);

        my $content = $j->raw('2376');
        like($content,qr/html/,'... contains html content');
        like($content,qr/Read\s+only\s+at\s+the\s+moment/,'... contains known text');
    }
}

