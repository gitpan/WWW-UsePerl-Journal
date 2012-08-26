#!/usr/bin/perl -w
use strict;

use lib 't/lib';
use PingTest;

use Data::Dumper;
use Test::More tests => 5;
use WWW::UsePerl::Journal;

my $pingtest = PingTest::pingtest('use.perl.org');

SKIP: {
	skip "Can't see a network connection", 5	if($pingtest);

    my $username = 'koschei';
    my $j = WWW::UsePerl::Journal->new($username);
    isa_ok($j, "WWW::UsePerl::Journal");

    my $uid = $j->uid();
    if($uid) {
        is($uid, 147, "uid");

        # validate recent entries
        my @entries = $j->recentarray;
        is(scalar(@entries), 30, "recentarray");

        # check caching
        my @cache = $j->recentarray;
        is_deeply(\@cache,\@entries, "cached recentarray");

        # removed direct comparison of the @entries and @authors lists as an extra
        # journal can (and does) slip between the test requests. 
    } else {
        diag("url=[http://use.perl.org/~$username/]");
        ok(0); ok(0); ok(0); ok(0);
    }

    $username = 'nosuchuser';
    my $k = WWW::UsePerl::Journal->new($username);
    $uid = $k->uid();
    is($uid, undef, "bad uid");
}
