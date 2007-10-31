#!/usr/bin/perl -w
use strict;


# Note:
# All dates coming back from use.perl are stored locally and manipulated by
# Time::Piece. This module is influenced by the timezone. No timezone testing
# is done by this distribution, so all dates are validate to be within 24 hours
# of the expected date.


use Test::More tests => 6;

use_ok('WWW::UsePerl::Journal');

my $j = WWW::UsePerl::Journal->new(147);
isa_ok($j, 'WWW::UsePerl::Journal');

my $e = $j->entry('8028');

SKIP: {
    skip 'WUJERR:' . $j->error(), 4   unless($e);

    isa_ok($e, 'WWW::UsePerl::Journal::Entry');

    my $s = $e->date->epoch;
    my $diff = abs($s - 1033030020);
    if($diff < 12 * 3600) {         # +/- 12 hours for a 24 hour period
        ok(1, 'Date matches.');
    } else {
        is $s => 1033030020, 'Date matches.';
    }

    $j = WWW::UsePerl::Journal->new(1296);
    $e = $j->entry('3107');
    my $date = eval { $e->date(); };
    is($@, '', 'date() doesnt die on entries posted between noon and 1pm');

    $s = $date->epoch;
    $diff = abs($s - 1014637200);
    if($diff < 12 * 3600) {         # +/- 12 hours for a 24 hour period
        ok(1, '...and gives the right date');
    } else {
        is $s => 1014637200, '...and gives the right date';
    }
}
