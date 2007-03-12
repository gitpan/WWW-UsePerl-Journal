#!/usr/bin/perl -w
use strict;

use Data::Dumper;
use Test::More tests => 6;
use WWW::UsePerl::Journal;

my $username = 'koschei';
my $j = WWW::UsePerl::Journal->new($username);
isa_ok($j, "WWW::UsePerl::Journal");

my $uid = $j->uid();
is($uid, 147, "uid");

my @entries = $j->recentarray;
isnt(scalar(@entries), 0, "recentarray");
# check caching
my @cache = $j->recentarray;
is_deeply(\@cache,\@entries, "cached recentarray");

my $content = $j->_journalsearch_content; # white box testing
my @authors;
while ($content =~ m#/~(\w+)/journal/\d+#g) {
    push @authors, $1;
}
@authors = sort @authors;

my @entry_authors = sort map { $_->author } @entries;

#use Data::Dumper;
#print "\n# entry_authors=".Dumper(\@entry_authors);
#print "\n# entries=".Dumper(\@entries);

is_deeply(\@entry_authors, \@authors, "...consistency check");

$username = 'nosuchuser';
my $k = WWW::UsePerl::Journal->new($username);
$uid = $k->uid();
is($uid, undef, "bad uid");

