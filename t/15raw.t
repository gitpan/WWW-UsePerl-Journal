#!/usr/bin/perl -w
use strict;

use lib 't/lib';
use PingTest;

use Test::More tests => 2;
use WWW::UsePerl::Journal;

my $pingtest = PingTest::pingtest('use.perl.org');

SKIP: {
	skip "Can't see a network connection", 2	if($pingtest);

    {
        my $j = WWW::UsePerl::Journal->new('russell');
        SKIP: {
            skip 'WUJERR: user not found', 2    unless($j);

            my $content = $j->raw('2376');
            skip 'WUJERR: no content for russell/2376', 2    unless($content);

            like($content,qr/html/i,'... contains html content');
            like($content,qr/Read\s+only\s+at\s+the\s+moment/i,'... contains known text');
        }
    }
}
