#!/usr/local/bin/perl -w

use strict;
use Data::Dumper;
use Test::More tests => 4;

use_ok('WWW::UsePerl::Journal');

my $username = 'koschei';
my $j = WWW::UsePerl::Journal->new($username);
isa_ok($j, "WWW::UsePerl::Journal");

my $UID = $j->uid();
is($UID, 147, "uid");

my @entries = $j->recentarray;
isnt(scalar @entries, 0, "recentarray");

warn Data::Dumper->Dump([\@entries, $entries[0]->content], [qw/entries content/]);
