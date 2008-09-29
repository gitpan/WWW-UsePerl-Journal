package WWW::UsePerl::Journal;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.22';

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

use LWP::UserAgent;
use HTTP::Cookies;
use HTTP::Request::Common;
use Carp;
use Time::Piece;

use WWW::UsePerl::Journal::Entry;
use WWW::UsePerl::Journal::Post;

# -------------------------------------
# Constants & Variables

my $UP_URL = 'http://use.perl.org';


# Regular Expressions for Journal Entries

my $JOURNAL = '(
            <div \s+ class="search-results">
            .*?
            <div \s+ class="author">
            .*?
            </div>
        )';

my $ENTRY = '
            <div \s+ class="search-results">
            \s+
            <h4> \s+ <a \s+ href=".*?~([\w.\+]+)/journal/(\d+)">(.+?)</a> \s+ </h4>
            \s+
            <div \s+ class="data">
            \s+ On \s+ (.+?) \s+ </div>
            \s+
            <div \s+ class="intro">
            \s+ .*? </div>
            \s+
            <div \s+ class="author">
            \s+ Author: \s+ <a \s+ href=".*?~(?:\1)/">[^<]+</a>
        ';

my $ENTRYLIST = '
            <tr> \s+
            <td \s+ valign="top"><a \s+ href="//use.perl.org/~[\w.\+]+/journal/(\d+)">
            <b>(.*?)</b></a></td> \s+
            <td \s+ valign="top"><em>(.*?)</em></td> \s+ </tr>
        ';

my $USER = '
            <title>Journal \s+ of \s+ (.*?) \s+ \(\d+\)
        ';

my $UID = '
            <div \s+ class="title" \s+ id="user-info-title"> \s+
            <h4> \s+ (.*?) \s+ \((\d+)\) \s+ </h4> \s+ </div>
        ';

# -------------------------------------
# The Public Interface

=head1 METHODS

=head2 new( [ $username | $userid ] )

  use WWW::UsePerl::Journal;
  my $j1 = WWW::UsePerl::Journal->new('russell');
  my $j2 = WWW::UsePerl::Journal->new(1413);

Creates an instance for the specified user, using either a username or userid.
Note that you must specify a name or id in order to instantiate the object.

=cut

sub new {
    my $class = shift;
    my $user  = shift or die "No user specified!";

    my $ua    = LWP::UserAgent->new(env_proxy => 1);
    $ua->cookie_jar(HTTP::Cookies->new());

    my $self  = bless {
        ($user =~ /^\d+$/ ? '_uid' : '_user') => $user,
        ua => $ua,
        }, $class;

    $self->{debug}   = 0;   # debugging off by default
    $self->{logmess} = '';  # clear message stack

    return $self;
}

=head2 error

If an error message given, sets the current message and returns undef. If no
message given returns that last error message.

=cut

sub error {
    my $self = shift;

    if(@_) {
        $self->{error} = shift;
        return;
    }

    $self->{error};
}

=head2 user

Returns the username

=cut

sub user {
    my $self = shift;
    $self->{_user} ||= do {
        my $uid = $self->uid;
        my $content = $self->{ua}->request(GET $UP_URL . "/journal.pl?op=list&uid=$uid")->content;
        return $self->error("Cannot connect to " . $UP_URL) unless ($content);
        return $self->error("Cannot obtain username.")      if($content =~ /<title>Journal \s+ of \s+ \($uid\)/six);

        if($self->{debug}) {
            $self->log('mess' => "\n#j->user: URL=[". $UP_URL . "/journal.pl?op=list&uid=$uid]\n");
            $self->log('mess' => "\n#content=[$content]\n");
        }

        $content =~ m!$USER!six or return $self->error("Cannot obtain username.");
        return $self->error("Cannot obtain username.")  unless($1);
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
        my $content = $self->{ua}->request(GET $UP_URL . "/~$user/")->content;
        return $self->error( "Cannot connect to " . $UP_URL )    unless $content;

        if($self->{debug}) {
            $self->log('mess' => "\n#j->uid: URL=[". $UP_URL . "/~$user/]\n");
            $self->log('mess' => "\n#content=[$content]\n");
        }

        $content =~ m!$UID!six or return $self->error("Cannot obtain userid.");
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
        my $content = $self->_recent_content;
        return $self->error( "Could not create search list - check your Internet connection" )
            unless $content;

        my @entries;
        my @content = ($content =~ m!$JOURNAL!igxs);

        for( @content ) {
            m!$ENTRY!ixs;
            my $time = Time::Piece->strptime($4, '%Y.%m.%d %H:%M');
            #$time += 4*ONE_HOUR; # correct TZ?

            push @entries, WWW::UsePerl::Journal::Entry->new(
                j       => $self,
                author  => $1,
                eid     => $2,
                subject => $3,
                date    => $time,
            );
        }

        \@entries;
    };

    return @{$self->{_recentarray}};
}

# Internal method: _journal_content
# Returns a string containing the interesting bit of the journal search page.
# Split out from recentarray method to make consistency testing easier.
sub _recent_content {
    my $self = shift;
    my $content = $self->{ua}->request( GET $UP_URL . "/search.pl?op=journals")->content;
    return $self->error("Cannot connect to " . $UP_URL . "/search.pl?op=journals")  unless ($content);

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
        my $uid  = $self->uid  || '';
        my $user = $self->user || '';
        return $self->error("Could not retrieve user details ($uid,$user)") unless $uid && $user;

        my $content = $self->{ua}->request(GET $UP_URL . "/journal.pl?op=list&uid=$uid")->content;
        return $self->error("Could not create entry list") unless $content;

        my %entries;

        if($self->{debug}) {
            $self->log('mess' => "\n#j->entryhash: URL=[". $UP_URL . "/journal.pl?op=list&uid=$uid]\n");
            $self->log('mess' => "\n#content=[$content]\n");
        }

        while ( $content =~ m!$ENTRYLIST!igxs ) {

            my $time = Time::Piece->strptime($3, '%Y.%m.%d %H:%M');
            #$time += 4*ONE_HOUR; # correct TZ?

            $entries{$1} = WWW::UsePerl::Journal::Entry->new(
                j       => $self,
                author  => $user,
                eid     => $1,
                subject => $2,
                date    => $time,
            );
        }

        if($self->{debug} && scalar(keys %entries) == 0) {
            $self->log('mess' => "\n#j->entryhash: URL=[". $UP_URL . "/journal.pl?op=list&uid=$uid]\n");
            $self->log('mess' => "\n#content=[$content]\n");
        }

        \%entries;
    };

    if(scalar(keys %{$self->{_entryhash}}) == 0) {
        $self->error('Cannot find entries!');
    }

    return %{$self->{_entryhash}};
}

=head2 entryids

Returns an array of the entry IDs

Can take an optional hash containing; {descending=>1} to return a descending
list of journal IDs, {ascending=>1} to return an ascending list or
{threaded=>1} to return a thread ordered list. The latter being the default.

=cut

sub entryids {
    my $self = shift;
    my %hash = @_;
    my ($key,$sorter) = ('_entryids_thd',sub{-1});	    # threaded
       ($key,$sorter) = ('_entryids_asc',\&_ascender)	if($hash{ascending});
       ($key,$sorter) = ('_entryids_dsc',\&_descender)	if($hash{descending});

    $self->{$key} ||= do {
        my %entries = $self->entryhash;
        my @ids;
        foreach (sort $sorter keys %entries) { push @ids, $_; }
        \@ids;
    };

    return $self->{$key} ? @{$self->{$key}} : ();
}

=head2 entrytitles

Returns an array of the entry titles

Can take an optional hash containing; {descending=>1} to return a descending
list of comment IDs, {ascending=>1} to return an ascending list or
{threaded=>1} to return a thread ordered list. The latter being the default.

=cut

sub entrytitles {
    my $self = shift;
    my %hash = @_;
    my ($key,$sorter) = ('_titles_thd',sub{-1});	    # threaded
       ($key,$sorter) = ('_titles_asc',\&_ascender)     if($hash{ascending});
       ($key,$sorter) = ('_titles_dsc',\&_descender)	if($hash{descending});

    $self->{$key} ||= do {
        my %entries = $self->entryhash;
        my @titles;
        foreach (sort $sorter keys %entries) { push @titles, $entries{$_}->subject; }
        \@titles;
    };

    return $self->{$key} ? @{$self->{$key}} : ();
}

=head2 entry

Returns the text of an entry, given an entry ID

=cut

sub entry {
    my $self   = shift;
    my $eid    = shift;
    my $author = $self->user;

    return WWW::UsePerl::Journal::Entry->new(
        j      => $self,
        author => $author,
        eid    => $eid,
    );
}

=head2 entrytitled

Returns an entry object given an entry title. To obtain the entry details use
the underlying object methods:

  my $e = $j->entrytitled('My Journal');
  my $eid     = $e->id;
  my $title   = $e->title;
  my $content = $e->content;

Note that prior to v0.21 this used a regular expression to match the user data
against the title. Due to this being a potential security risk, as of v0.22 the
title passed to this method is now required to be a string that will match all
or part of the journal title you require.

=cut

sub entrytitled {
    my $self    = shift;
    my $title   = shift;
    my %entries = $self->entryhash;

    for(keys %entries) {
        next    if(index($entries{$_}->subject,$title) == -1);
        return $self->entry($_);
    }
    return $self->error("$title does not exist");
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
    return WWW::UsePerl::Journal::Post->new(
        j        => $self,
        username => $user,
        password => $pass
    );
}

=head1 DEBUG METHODS

=head2 debug

Turns internal debugging on or off. Use a true or false expression to set
value as appropriate. Returns current status.

=cut

sub debug {
    my $self = shift;
    if(defined $_[0]) {
        $self->{debug}   = shift;
        $self->{logmess} = '';
    }
    return $self->{debug};
}

=head2 log

Used to record internal debugging messages. Call externally with no arguments
to retrieve the current list of messages.

=cut

sub log {
    my $self = shift;
    my %hash = @_;

    $self->{logmess}  = ''          if($hash{clear});
    $self->{logmess} .= $hash{mess} if($hash{mess});
    return  if(@_);

    return $self->{logmess};
}

=head2 raw

For debugging purposes.

=cut

sub raw {
    my $self   = shift;
    my $eid    = shift;
    my $author = $self->user;

    my $e = WWW::UsePerl::Journal::Entry->new(
        j      => $self,
        author => $author,
        eid    => $eid,
    );

    return $e->raw();
}

# -------------------------------------
# The Private Methods

# sort methods

sub _ascender  { $a <=> $b }
sub _descender { $b <=> $a }

1;
__END__

=head1 TODO

=over

=item * Better error checking and test suite.

=item * Comment retrieval - see L<WWW-UsePerl-Journal-Thread>

=item * Writing activities (modify, delete ...)

=back

=head1 CAVEATS

Beware the stringification of WWW::UsePerl::Journal::Entry objects.
They're still objects, they just happen to look the same as before when
you're printing them. Use -E<gt>content instead.

The time on a journal entry is the localtime of the user that created the
journal entry. If you aren't in the same timezone, that time can appear an
hour out.

=head1 SEE ALSO

F<http://use.perl.org/>,
F<LWP>

=head1 SUPPORT

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties that are not explained within the POD
documentation, please submit a bug to the RT system (see link below). However,
it would help greatly if you are able to pinpoint problems or even supply a
patch.

Fixes are dependant upon their severity and my availablity. Should a fix not
be forthcoming, please feel free to (politely) remind me by sending an email
to barbie@cpan.org .

RT: L<http://rt.cpan.org/Public/Dist/Display.html?Name=WWW-UsePerl-Journal>

=head1 AUTHOR

  Original author: Russell Matbouli
  <www-useperl-journal-spam@russell.matbouli.org>,
  <http://russell.matbouli.org/>

  Current maintainer: Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 CONTRIBUTORS

Thanks to Iain Truskett, Richard Clamp, Simon Wilcox, Simon Wistow and
Kate L Pugh for sending patches. 'jdavidb' also contributed two stats
scripts.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2002-2004 Russell Matbouli.
  Copyright (C) 2005-2007 Barbie for Miss Barbell Productions.

  This module is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.

The full text of the licenses can be found in the F<Artistic> and
F<COPYING> files included with this module, or in L<perlartistic> and
L<perlgpl> in Perl 5.8.1 or later.

=cut

