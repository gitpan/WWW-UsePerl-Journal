#!/usr/bin/perl -w

use strict;
use Test::More skip_all => "Currently broken";

#use Test::More tests => 6;

use_ok('WWW::UsePerl::Journal');

my $j = WWW::UsePerl::Journal->new(147);
isa_ok($j, "WWW::UsePerl::Journal");

my $e = $j->entry('8028');
isa_ok($e, "WWW::UsePerl::Journal::Entry");

my $s = $e->date->epoch;

is $s => 1033030020, "Date matches.";

$j = WWW::UsePerl::Journal->new(1296);
$e = $j->entry('3107');
my $date = eval { $e->date(); };
is($@, "", "date() doesn't die on entries posted between noon and 1pm");
is($date->epoch, "1014597600", "...and gives the right date");
