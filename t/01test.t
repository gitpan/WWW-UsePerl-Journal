#!/usr/local/bin/perl -w

use strict;
use Test::More tests => 20;

use_ok('WWW::UsePerl::Journal');

my $j = WWW::UsePerl::Journal->new();

isa_ok($j, "WWW::UsePerl::Journal");

# Test getUID
my $username = "russell";
my $UID = $j->getUID($username);
isnt($UID, undef, "getUID returns defined");
isnt($UID, "", "getUID doesn't return empty string");
is($UID, 1413, "getUID gets the right ID");

# Test getEntryList
my @entries = $j->getEntryList($username);
isnt($#entries, 0, "getEntryList got more than one entry");
isnt($entries[0], undef, "getEntryList's first entry isn't undef");
isnt($entries[0], "", "getEntryList's first entry isn't empty");

# Test getEntryIDs
my @IDs = $j->getEntryIDs($username);
isnt($#IDs, 0, "getEntryIDs got more than one entry");
isnt($IDs[0], undef, "getEntryIDs first entry isn't undef");
isnt($IDs[0], "", "getEntryIDs first entry isn't empty");

# Test getEntryTitles
my @titles = $j->getEntryTitles($username);
isnt($#titles, 0, "getEntryTitles got more than one entry");
isnt($titles[0], undef, "getEntryTitles first entry isn't undef");
isnt($titles[0], "", "getEntryTitles first entry isn't empty");

# Test getEntryByID
my $EID = $j->getEntryByID($username, "2340");
isnt($EID, undef, "getEntryByID returns defined");
isnt($EID, "", "getEntryByID doesn't return empty string");
is($EID, "I read in <A HREF=\"~hfb/journal/\">hfb's journal</A> that there was no module for testing whether something was a pangram. There is now.", "getEntryByID gets the right stuff");

# Test getEntryByTitle
my $text = $j->getEntryByTitle($username, "Lingua::Pangram");
isnt($text, undef, "getEntryByTitle returns defined");
isnt($text, "", "getEntryByTitle doesn't return empty string");
is($text, "I read in <A HREF=\"~hfb/journal/\">hfb's journal</A> that there was no module for testing whether something was a pangram. There is now.", "getEntryByID gets the right stuff");

