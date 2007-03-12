#!/usr/bin/perl -w
use strict;

use Test::More tests => 20;
use WWW::UsePerl::Journal;

my $username = "russell";
my $j = WWW::UsePerl::Journal->new($username);
isa_ok($j, "WWW::UsePerl::Journal");

my $UID = $j->uid();
is($UID, 1413, "uid");

my %entries = $j->entryhash;
isnt(scalar %entries, 0, "entryhash");
my %cache = $j->entryhash;
is_deeply(\%cache,\%entries, "cached entryhash");

# check entry ids
my @ids = $j->entryids;
isnt(scalar @ids, 0, "entryids");
   @ids = sort {$a <=> $b} @ids;
my @asc = $j->entryids(ascending  => 1);
my @des = $j->entryids(descending => 1);
my @rev = reverse @des;
is_deeply(\@asc,\@ids,'ascending entryids');
is_deeply(\@rev,\@ids,'descending entryids');

# check caching
my @c_ids = $j->entryids;
my @c_asc = $j->entryids(ascending  => 1);
my @c_des = $j->entryids(descending => 1);
is_deeply(\@c_ids,\@c_ids,'cached threaded entryids');
is_deeply(\@c_asc,\@asc,'cached ascending entryids');
is_deeply(\@c_des,\@des,'cached descending entryids');

# check entry titles
my @titles = $j->entrytitles;
isnt(scalar @titles, 0, "entrytitles");
@asc = $j->entrytitles(ascending  => 1);
@des = $j->entrytitles(descending => 1);
@rev = reverse @des;
is_deeply(\@rev,\@asc,'ordered entrytitles');

# check caching
my @c_titles = $j->entrytitles;
@c_asc = $j->entrytitles(ascending  => 1);
@c_des = $j->entrytitles(descending => 1);
is_deeply(\@c_titles,\@titles,'cached threaded entrytitles');
is_deeply(\@c_asc,\@asc,'cached ascending entrytitles');
is_deeply(\@c_des,\@des,'cached descending entrytitles');

my $text = 'I read in <a href="~hfb/journal/" rel="nofollow">hfb\'s journal</a> that there was no module for testing whether something was a pangram. There is now.';
my $content = $j->entry('2340')->content;
cmp_ok($content, 'eq', $text, 'entry compare' );
$content = $j->entrytitled('Lingua::Pangram')->content;
cmp_ok($content, 'eq', $text, 'entrytitled compare' );

my $k = WWW::UsePerl::Journal->new(1662);
cmp_ok($k->user, 'eq', 'richardc', "username from uid");

$j = WWW::UsePerl::Journal->new('2shortplanks');
%entries = eval { $j->entryhash; };
is($@, "", "entryhash doesn't die on titles with trailing newlines");
isnt(scalar %entries, 0, "...and has found some entries");
