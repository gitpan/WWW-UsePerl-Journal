#!/usr/bin/perl -w
use strict;

use Data::Dumper;
use Test::More tests => 5;
use WWW::UsePerl::Journal;

my $username = 'koschei';
my $j = WWW::UsePerl::Journal->new($username);
isa_ok($j, "WWW::UsePerl::Journal");

my $UID = $j->uid();
is($UID, 147, "uid");

my @entries = $j->recentarray;
isnt(scalar(@entries), 0, "recentarray");

my $content = $j->_journalsearch_content; # white box testing
my @users;
while ($content =~ m#/~(\w+)/journal/\d+#g) {
    push @users, $1;
}

my @entry_users = map { $_->user } @entries;
is_deeply(\@entry_users, \@users, "...consistency check");

$username = 'nosuchuser';
my $k = WWW::UsePerl::Journal->new($username);
$UID = $k->uid();
is($UID, undef, "bad uid");

