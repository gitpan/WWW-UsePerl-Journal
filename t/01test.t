#!/usr/local/bin/perl -w

use strict;
use Test::More tests => 9;

use_ok('WWW::UsePerl::Journal');

my $username = "russell";
my $j = WWW::UsePerl::Journal->new($username);
isa_ok($j, "WWW::UsePerl::Journal");

my $UID = $j->uid();
is($UID, 1413, "uid");

my %entries = $j->entryhash;
isnt(scalar %entries, 0, "entryhash");

my @IDs = $j->entryids;
isnt(scalar @IDs, 0, "entryids");

my @titles = $j->entrytitles;
isnt(scalar @titles, 0, "entrytitles");

my $EID = $j->entry("2340");
cmp_ok("$EID", 'eq',
'I read in <A HREF="~hfb/journal/">hfb\'s journal</A> that there was no module for testing whether something was a pangram. There is now.',
"entry");

my $text = $j->entrytitled("Lingua::Pangram");
cmp_ok("$text", 'eq',
'I read in <A HREF="~hfb/journal/">hfb\'s journal</A> that there was no module for testing whether something was a pangram. There is now.', 
"entrytitled");

my $k = new WWW::UsePerl::Journal 1662;
cmp_ok($k->user, 'eq', 'richardc', "username from uid");
