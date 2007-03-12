#!/usr/bin/perl -w

use strict;
#use Test::More skip_all => "Currently broken";

use Test::More tests => 6;

use_ok('WWW::UsePerl::Journal');

my $j = WWW::UsePerl::Journal->new(147);
isa_ok($j, "WWW::UsePerl::Journal");

my $e = $j->entry('8028');
isa_ok($e, "WWW::UsePerl::Journal::Entry");

my $s = $e->date->epoch;

# note dates coming back from use.perl can change hour
if($s == 1033030020 || $s == 1033026420) { 
    ok(1, "Date matches.");
} else {
    is $s => 1033030020, "Date matches.";
}

$j = WWW::UsePerl::Journal->new(1296);
$e = $j->entry('3107');
my $date = eval { $e->date(); };
is($@, "", "date() doesn't die on entries posted between noon and 1pm");

# note dates coming back from use.perl can change hour
$s = $date->epoch;
if($s == 1014637200 || $s == 1014633600) { 
    ok(1, "...and gives the right date");
} else {
    is $s => 1014637200, "...and gives the right date";
}
