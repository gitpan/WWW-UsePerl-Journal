#!/usr/bin/perl -w
use strict;

use Test::More tests => 3;
use WWW::UsePerl::Journal;

my $j;

eval { $j = WWW::UsePerl::Journal->new(); };
like($@,qr/^We need a user!/);

my $username = 'nosuchuser';
$j = WWW::UsePerl::Journal->new($username);
is($j->uid, undef, "bad username");

my $userid = "999999";
$j = WWW::UsePerl::Journal->new($userid);
is($j->user, '', "bad userid");

