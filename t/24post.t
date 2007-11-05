#!/usr/bin/perl -w
use strict;

use Test::More tests => 26;
use WWW::UsePerl::Journal;
use WWW::UsePerl::Journal::Post;

my $username = 'russell';
my $password = '';

my $j = WWW::UsePerl::Journal->new($username);
isa_ok($j,'WWW::UsePerl::Journal','Login User');
my $p = $j->login('badpassword');
is($p,undef,'... bad login');

# NOTE:
# these tests are currently disabled as I do not want a test account getting
# polluted with nonsense. Plus I don't think the guys at use.perl would
# appreciate it either. If you do wish to enable this test, please update
# the username/password with your own account details.

$username = '';
$password = '';

SKIP: {
    skip "Username/Password not set for testing", 24 unless($username && $password);

    ### ---- LOGIN --- ###

    my $j = WWW::UsePerl::Journal->new($username);
    isa_ok($j,'WWW::UsePerl::Journal','User');
    my $p = $j->login('badpassword');
    is($p,undef,'... bad login');
    $p = $j->login($password);
    isa_ok($p,'WWW::UsePerl::Journal::Post','... good login');

    my %entries = $j->entryhash;

    ### ---- POST AN ENTRY --- ###

    # basic entry fields
    my $title = 'My journal is great';
    my $text  = 'It really is';
    my $res;

    # test post type (1..4)
    $res = $p->postentry(title => $title, text => $text, type => 0);
    is($res,undef,'post type too low');
    is($j->error, 'Invalid post type.', '... error: post type too low');
    $res = $p->postentry(title => $title, text => $text, type => 5);
    is($res,undef,'post type too high');
    is($j->error, 'Invalid post type.', '... error: post type too high');

    # test topic (1..15,17..37,44)
    $res = $p->postentry(title => $title, text => $text, topic => 0);
    is($res,undef,'topic id too low');
    is($j->error, 'Invalid journal topic.', '... error: topic id too low');
    $res = $p->postentry(title => $title, text => $text, topic => 38);
    is($res,undef,'topic id too high');
    is($j->error, 'Invalid journal topic.', '... error: topic id too high');
    $res = $p->postentry(title => $title, text => $text, topic => 16);
    is($res,undef,'topic id invalid');
    is($j->error, 'Invalid journal topic.', '... error: topic id invalid');

    # test promotion type (publish|publicize|post)
    $res = $p->postentry(title => $title, text => $text, promote => 'me');
    is($res,undef,'invalid promotion type');
    is($j->error, 'Invalid promotion type.', '... error: invalid promotion type');

    # test title length
    $res = $p->postentry(title => 'X' x 61, text => $text);
    is($res,undef,'title too long');
    is($j->error, 'Subject too long.', '... error: title too long');

    # use defaults
    $res = $p->postentry(title => $title, text => $text);
    is($res,1,'posted');
    if(!$res) { print STDERR "\n# post error: ".($j->error)."\n"; }
    
    # is it in the cached version?
    my $e = $j->entrytitled($title);
    is($e, undef, '... not in cached version' );

    # is it in the cache after a refresh?
    $j->refresh();
    $e = $j->entrytitled($title);
    isnt($e, undef, '... found it!' );
    cmp_ok($e->content, 'eq', $text, '... with the right text' );

    ### ---- DELETE AN ENTRY --- ###

    # can we delete the new entry?
    $res = $p->deleteentry($e->eid);
    is($res,1,'deleted');
    $j->refresh();
    $e = $j->entrytitled($title);
    is($e, undef, '... deleted entry' );

    my %newentries = $j->entryhash;
    is(scalar(%newentries),scalar(%entries),'got what we started with');
}