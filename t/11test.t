#!/usr/bin/perl -w
use strict;

use Test::More tests => 16;
use WWW::UsePerl::Journal;

my $username = "russell";
my $j = WWW::UsePerl::Journal->new($username);
isa_ok($j, "WWW::UsePerl::Journal");

my $UID = $j->uid();
is($UID, 1413, "uid");

my %entries = $j->entryhash;
isnt(scalar %entries, 0, "entryhash");

my @ids = $j->entryids;
isnt(scalar @ids, 0, "entryids");
my @asc = $j->entryids({ascending=>1});
is(scalar @asc, scalar @ids, "ascending entryids");
my @des = $j->entryids({descending=>1});
is(scalar @des, scalar @ids, "descending entryids");
my @rev = reverse @des;
is_deeply(\@rev,\@asc,'deep check entryids');

my @titles = $j->entrytitles;
isnt(scalar @titles, 0, "entrytitles");
@asc = $j->entrytitles({ascending=>1});
is(scalar @asc, scalar @titles, "ascending entrytitles");
@des = $j->entrytitles({descending=>1});
is(scalar @des, scalar @titles, "descending entrytitles");
@rev = reverse @des;
is_deeply(\@rev,\@asc,'deep check entrytitles');

my $text = 'I read in <a href="~hfb/journal/" rel="nofollow">hfb\'s journal</a> that there was no module for testing whether something was a pangram. There is now.';
my $content = $j->entry('2340');
cmp_ok($content, 'eq', $text, 'entry compare' );
$content = $j->entrytitled('Lingua::Pangram');
cmp_ok($content, 'eq', $text, 'entrytitled compare' );

my $k = WWW::UsePerl::Journal->new(1662);
cmp_ok($k->user, 'eq', 'richardc', "username from uid");

$j = WWW::UsePerl::Journal->new('2shortplanks');
%entries = eval { $j->entryhash; };
is($@, "", "entryhash doesn't die on titles with trailing newlines");
isnt(scalar %entries, 0, "...and has found some entries");
