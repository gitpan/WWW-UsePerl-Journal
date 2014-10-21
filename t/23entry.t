#!/usr/bin/perl -w
use strict;

use Test::More tests => 10;
use WWW::UsePerl::Journal;
use WWW::UsePerl::Journal::Entry;

my $username = "russell";
my $entryid  = 2376;
my $userid   = 1413;

my $j = WWW::UsePerl::Journal->new($username);
my $e = WWW::UsePerl::Journal::Entry->new(j=>$j);
is($e,undef);
$e = WWW::UsePerl::Journal::Entry->new(j=>$j,author=>$username,eid=>$entryid);
isa_ok($e,'WWW::UsePerl::Journal::Entry');

SKIP: {
    skip 'WUJERR: ' . $j->error(), 8    unless($e);

    $j->debug(1);
    is($e->eid,       $entryid, 'entry id');
    is($e->author,    $username,'user name');

    if($e->uid) {
        is($e->uid,       $userid,  'user id');
        is($e->subject,   'WWW::UsePerl::Journal',       'subject');
        like($e->date,    qr/Thu Jan 24 \d+:10:00 2002/, 'date');
        like($e->content, qr/^Get it from CPAN now/,     'content');

        # can we find after a refresh?
        $j->refresh;
        $e = $j->entrytitled('WWW::UsePerl::Journal');
        isa_ok($e,'WWW::UsePerl::Journal::Entry');
        is($e->uid,       $userid,  'user id');

    } else {
        diag("url=[http://use.perl.org/~$username/journal/$entryid]");
        diag('raw=[' . $j->raw($entryid) . ']');
        diag('log=[' . $j->log() . ']');
        ok(0); ok(0); ok(0); ok(0); ok(0); ok(0);
    }
}