#!/usr/local/bin/perl -w

use strict;
use Test::More tests => 8;

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
is($EID,
"I read in <A HREF=\"~hfb/journal/\">hfb's journal</A> that there was no module for testing whether something was a pangram. There is now.",
"entry");

my $text = $j->entrytitled("Lingua::Pangram");
is($text,
"I read in <A HREF=\"~hfb/journal/\">hfb's journal</A> that there was no module for testing whether something was a pangram. There is now.",
"entrytitled");
