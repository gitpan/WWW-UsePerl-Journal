#!/usr/bin/perl -w
use strict;

use Test::More tests => 21;
use WWW::UsePerl::Journal;

my $username = "russell";
my $entryid  = 2376;
my $userid   = 1413;

{
    my $j = WWW::UsePerl::Journal->new($username);
    isa_ok($j, 'WWW::UsePerl::Journal');

    my $uid = $j->uid();

    SKIP: {
        skip 'WUJERR: ' . $j->error(), 17    unless($uid);
        is($uid, $userid, 'uid');

        my %entries = $j->entryhash;
        isnt(scalar(keys %entries), 0, 'entryhash');
        if(scalar(keys %entries) == 0) {
            diag("url=[http://use.perl.org/~$username/]");
            diag("WUJERR: " . $j->error);
        }
        my %cache = $j->entryhash;
        is(scalar(keys %cache),scalar(keys %entries), 'matching cached/entryhash count');
        is_deeply(\%cache,\%entries, 'matching cached/entryhash values');

        # check entry ids
        my @ids = $j->entryids;
        isnt(scalar(@ids), 0, 'entryids');
        if(scalar(@ids) == 0) {
            diag("url=[http://use.perl.org/~$username/]");
            diag("WUJERR: " . $j->error);
        }

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
        isnt(scalar @titles, 0, 'entrytitles');
        if(scalar(@titles) == 0) {
            diag("url=[http://use.perl.org/~$username/]");
            diag("WUJERR: " . $j->error);
        }
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

        # find another entry
        $j->debug(1);
        my $text = 'I read in <a href="~hfb/journal/" rel="nofollow">hfb\'s journal</a> that there was no module for testing whether something was a pangram. There is now.';
        my $content = $j->entry('2340')->content;

        unless($content) {
            diag("url=[http://use.perl.org/~$username/journal/2340]");
            diag($j->log());
        }

        SKIP: {
            skip 'WUJERR: ' . $j->error(), 2    unless($content);
            cmp_ok($content, 'eq', $text, 'entry compare' );
            $content = $j->entrytitled('Lingua::Pangram')->content;
            cmp_ok($content, 'eq', $text, 'entrytitled compare' );
        }
    }
}

{
    my $j = WWW::UsePerl::Journal->new(1662);
    my $user = $j->user;
    is($user, 'richardc', 'username from uid');
    if($user ne 'richardc') {
        diag("url=[http://use.perl.org//journal.pl?op=list&uid=1662]");
        diag("WUJERR: " . $j->error);
    }
}

{
    my $j = WWW::UsePerl::Journal->new('2shortplanks');
    my %entries = eval { $j->entryhash; };
    is($@, '', 'entryhash doesnt die on titles with trailing newlines');
    isnt(scalar(keys %entries), 0, '...and has found some entries');
    if(scalar(keys %entries) == 0) {
        diag("url=[http://use.perl.org/~2shortplanks/]");
        diag("WUJERR: " . $j->error);
    }
}
