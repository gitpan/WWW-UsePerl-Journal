#!/usr/local/bin/perl -w

use strict;
use Test::More tests => 4;

use_ok('WWW::UsePerl::Journal');

my $j = WWW::UsePerl::Journal->new(147);
isa_ok($j, "WWW::UsePerl::Journal");

my $e = $j->entry('8028');
isa_ok($e, "WWW::UsePerl::Journal::Entry");

my $s = $e->date->epoch;

is $s => 1033030020, "Date matches."
