#!/usr/bin/perl -w
use strict;

use Test::More tests => 8;
use WWW::UsePerl::Journal;
use WWW::UsePerl::Journal::Entry;

my $username = "russell";
my $entryid  = 2376;

my $j = WWW::UsePerl::Journal->new($username);
my $e = WWW::UsePerl::Journal::Entry->new(j=>$j);
is($e,undef);
$e = WWW::UsePerl::Journal::Entry->new(j=>$j,id=>$entryid);
isa_ok($e,'WWW::UsePerl::Journal::Entry');

is($e->id,        $entryid, 'entry id');
is($e->user,      $username,'user name');
is($e->uid,       1413,     'user id');
is($e->date,      'Thu Jan 24 11:10:00 2002',   'date');
is($e->subject,   'WWW::UsePerl::Journal',      'subject');
like($e->content, qr/^Get it from CPAN now/,    'content');
