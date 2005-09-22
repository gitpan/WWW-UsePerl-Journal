package WWW::UsePerl::Journal;

our $VERSION = '0.14';

#----------------------------------------------------------------------------

=head1 NAME

WWW::UsePerl::Journal - A use.perl.org journal tool

=head1 SYNOPSIS

  use WWW::UsePerl::Journal;
  my $journal = WWW::UsePerl::Journal->new('russell')
  print $journal->entrytitled("Text::Echelon");
  my @entries = $journal->entrytitles();

=head1 DESCRIPTION

An all round journal tool for use.perl addicts. Will access journal entries
for a specific user, or the latest 30 postings, or retrieve a specific
journal entry. Can also post into a specific user's journal.

=cut

# -------------------------------------
# Library Modules

use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Cookies;
use HTTP::Request::Common;
use Carp;
use Time::Piece;

use WWW::UsePerl::Journal::Entry;
use WWW::UsePerl::Journal::Post;

# -------------------------------------
# Constants & Variables

use constant UP_URL => 'http://use.perl.org';


# Regular Expressions for Journal Entries

my $JOURNAL = '
            <div \s+ class="search-results">
            \s+
            <h4> \s+ <a \s+ href=".*?~(\w+)/journal/(\d+)">(.+?)</a> \s+ </h4>
            \s+
            <div \s+ class="data">
            \s+ On \s+ (.+?) \s+ </div>
            \s+
            <div \s+ class="intro">
            \s+ .*? </div>
            \s+
            <div \s+ class="author">
            \s+ Author: \s+ <a \s+ href=".*?~(?:\1)/">(?:\1)</a>
        ';

my $ENTRYLIST = '
            <tr> \s+
            <td \s+ valign="top"><a \s+ href="//use.perl.org/~\w+/journal/(\d+)">
            <b>(.*?)</b></a></td> \s+
            <td \s+ valign="top"><em>(.*?)</em></td> \s+ </tr>
        ';

my $USER = '
            <title>Journal \s+ of \s+ (.*?) \s+ \(\d+\) \s* </title>
        ';

my $UID = '
            <div \s+ class="title" \s+ id="user-info-title"> \s+ 
            <h4> \s+ (.*?) \s+ \((\d+)\) \s+ </h4> \s+ </div>
        ';

# -------------------------------------
# The Public Interface

=head1 METHODS

=head2 new

  use WWW::UsePerl::Journal;
  my $j = WWW::UsePerl::Journal-E<gt>new('russell');

Creates an instance for the specified user.

=cut

sub new {
    my $class = shift;
    my $user  = shift or die "We need a user!";

    my $ua    = LWP::UserAgent->new(env_proxy => 1);
    $ua->cookie_jar(HTTP::Cookies->new());

    my $self  = bless { 
        ($user =~ /^\d+$/ ? '_uid' : '_user') => $user,
        ua => $ua,
        }, $class;

    return $self;
}

=head2 user

Returns the username

=cut

sub user {
    my $self = shift;
    $self->{_user} ||= do {
        my $uid = $self->uid;
        my $content = $self->{ua}->request(GET UP_URL .
            "/journal.pl?op=list&uid=$uid")->content;
        carp "Cannot connect to " . UP_URL unless $content;

#print STDERR "\n#j->user: URL=[". UP_URL . "/journal.pl?op=list&uid=$uid]\n";
#print STDERR "\n#content=[$content]\n";

        $content =~ m!$USER!six or return undef;
        $1;
    }
}

=head2 uid

Returns the user ID

=cut

sub uid {
    my $self = shift;
    $self->{_uid} ||= do {
        my $user = $self->user;
        my $content = $self->{ua}->request(GET UP_URL . "/~$user/")->content;
        carp "Cannot connect to " . UP_URL unless $content;

#print STDERR "\n#j->uid: URL=[". UP_URL . "/~$user/]\n";
#print STDERR "\n#content=[$content]\n";

        $content =~ m!$UID!six or return undef;
        $2;
    }
}

=head2 recentarray

Returns an array of the 30 most recently posted WWW::UsePerl::Journal::Entry
objects.

=cut

sub recentarray {
    my $self = shift;
    $self->{_recentarray} ||= do
    {
        my $content = $self->_journalsearch_content;
        carp "Could not create search list - check your Internet connection" 
            unless $content;

        my @entries;

        while ( $content =~ m!$JOURNAL!igxs ) {
            my $time = Time::Piece->strptime($4, '%Y.%m.%d %H:%M');
            #$time += 4*ONE_HOUR; # correct TZ?

            push @entries, WWW::UsePerl::Journal::Entry->new(
                j       => $self,
                user    => $1,
                id      => $2,
                subject => $3,
                date    => $time,
            );
        }

        return @entries;
    }
}

# Internal method: _journalsearch_content
# Returns a string containing the interesting bit of the journal search page.
# Split out from recentarray method to make consistency testing easier.
sub _journalsearch_content {
    my $self = shift;
    my $content = $self->{ua}->request(
        GET UP_URL . "/search.pl?op=journals")->content;

    $content =~ s/^.*\Q<div class="journalsearch">//sm;
    $content =~ s/<div class="pagination">.*$//sm;

    return $content;
}

=head2 entryhash

Returns a hash of WWW::UsePerl::Journal::Entry objects

=cut

sub entryhash {
    my $self = shift;
    $self->{_entryhash} ||= do {
        my $uid  = $self->uid;
        my $user = $self->user;

        my $content = $self->{ua}->request(
            GET UP_URL . "/journal.pl?op=list&uid=$uid")->content;
        carp "could not create entry list" unless $content;

        my %entries;

#print STDERR "\n#j->entryhash: URL=[". UP_URL . "/journal.pl?op=list&uid=$uid]";
#print STDERR "\n#content=[$content]\n";

        while ( $content =~ m!$ENTRYLIST!igxs ) {

            my $time = Time::Piece->strptime($3, '%Y.%m.%d %H:%M');
            #$time += 4*ONE_HOUR; # correct TZ?

            $entries{$1} = WWW::UsePerl::Journal::Entry->new(
                j       => $self,
                user    => $user,
                id      => $1,
                subject => $2,
                date    => $time,
            );
        }

        return %entries;
    }
}

=head2 entryids

Returns an array of the entry IDs

Can take an optional hash containing; {descending=>1} to return a descending 
list of journal IDs, {ascending=>1} to return an ascending list or 
{threaded=>1} to return a thread ordered list. The latter being the default.

=cut

sub entryids {
    my $self = shift;
    my $hash = shift;
    my ($key,$sorter) = ('_entryids_thd',sub{-1});	# threaded
    ($key,$sorter) = ('_entryids_asc',\&_ascender)	if(defined $hash && $hash->{ascending});
    ($key,$sorter) = ('_entryids_dsc',\&_descender)	if(defined $hash && $hash->{descending});

    $self->{$key} ||= do {
        my %entries = $self->entryhash;
        my @ids;

        foreach (sort $sorter keys %entries) {
            $ids[$#ids+1] = $_;
        }
        return @ids;
    }
}

=head2 entrytitles

Returns an array of the entry titles

Can take an optional hash containing; {descending=>1} to return a descending 
list of comment IDs, {ascending=>1} to return an ascending list or 
{threaded=>1} to return a thread ordered list. The latter being the default.

=cut

sub entrytitles {
    my $self = shift;
    my $hash = shift;
    my ($key,$sorter) = ('_titles_thd',sub{-1});	# threaded
    ($key,$sorter) = ('_titles_asc',\&_ascender)	if(defined $hash && $hash->{ascending});
    ($key,$sorter) = ('_titles_dsc',\&_descender)	if(defined $hash && $hash->{descending});

    $self->{$key} ||= do {
        my %entries = $self->entryhash;
        my @titles;

        foreach (sort $sorter keys %entries) {
            $titles[$#titles+1] = $entries{$_}->subject;
        }
        return @titles;
    }
}

=head2 entry

Returns the text of an entry, given an entry ID

=cut

sub entry {
    my $self = shift;
    my $id   = shift;

    my $entry = WWW::UsePerl::Journal::Entry->new(
        j     => $self,
        id    => $id,
    );

    return undef    unless($entry);
    return $entry->content;
}

=head2 entrytitled

Returns the text of an entry, given an entry title

=cut

sub entrytitled {
    my $self    = shift;
    my $title   = shift;
    my %entries = $self->entryhash;

    foreach (keys %entries) {
        next unless $entries{$_}->subject =~ /$title/ism;
        return $self->entry($_);
    }
    carp "$title does not exist";
}

=head2 refresh

To save time, entries are cached. However, following a post or 
period of waiting, you may want to refresh the list. This functions
allows you to clear the cache and start again.

=cut

sub refresh {
    my $self    = shift;
    $self->{$_} = () 
        for(   '_recentarray','_entryhash',
               '_titles_thd','_titles_asc','_titles_dsc',
               '_entryids_thd','_entryids_asc','_entryids_dsc');
}

=head2 login

Required before posting can occur, takes the password.

  my $post = $j->login($password);

=cut

sub login {
    my ($self, $pass) = (@_);
    my $user  = $self->user;
    return WWW::UsePerl::Journal::Post->new({
        username => $user,
        password => $pass
    });
}

# sort methods

sub _ascender  { $a <=> $b }
sub _descender { $b <=> $a }

1;
__END__

=head1 TODO

Better error checking and test suite.

Comment retrieval.

Writing activities (modify, delete ...)

=head1 CAVEATS

Beware the stringification of WWW::UsePerl::Journal::Entry objects. 
They're still objects, they just happen to look the same as before when
you're printing them. Use -E<gt>content instead.

The time on a journal entry is the localtime of the user that created the 
journal entry. If you aren't in the same timezone, that time will be wrong.

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties, that is not explained within the POD
documentation, please send an email to barbie@cpan.org or submit a bug to the
RT system (http://rt.cpan.org/). However, it would help greatly if you are 
able to pinpoint problems or even supply a patch. 

Fixes are dependant upon their severity and my availablity. Should a fix not
be forthcoming, please feel free to (politely) remind me.

=head1 SEE ALSO

F<http://use.perl.org/>

F<LWP>

=head1 AUTHOR

Original author was Russell Matbouli 
E<lt>www-useperl-journal-spam@russell.matbouli.orgE<gt>, 
F<http://russell.matbouli.org/>

Current maintainer is Barbie <barbie@cpan.org>.

=head1 CONTRIBUTORS

Thanks to Iain Truskett, Richard Clamp, Simon Wilcox, Simon Wistow and
Kate L Pugh for sending patches. 'jdavidb' also contributed two stats
scripts.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2002-2004 Russell Matbouli.
  Copyright (C) 2005      Barbie for Miss Barbell Productions.
  All Rights Reserved.

  Distributed under GPL v2. See F<COPYING> included with this distibution.

=cut

