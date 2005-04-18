package WWW::UsePerl::Journal;

=head1 NAME

WWW::UsePerl::Journal - use.perl.org journal tool

=head1 SYNOPSIS

  use WWW::UsePerl::Journal;
  my $journal = WWW::UsePerl::Journal->new('russell')
  print $journal->entrytitled("Text::Echelon");
  my @entries = $journal->entrytitles();

=head1 DESCRIPTION

Can list journal entries for a user.
Can display a specific journal entry.
Can post into a journal.

=cut

use strict;
use warnings;
use LWP::UserAgent;
use HTTP::Cookies;
use HTTP::Request::Common;
use Data::Dumper;
use Carp;
use Time::Piece;
use WWW::UsePerl::Journal::Entry;


use constant UP_URL => 'http://use.perl.org';
my $site = '//use.perl.org';

my %postdefaults = (
    topic     => 34,
    comments  => 1,
    type      => 1,
);


our $VERSION = '0.12';

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
        die "Cannot connect to " . UP_URL unless $content;

        $content =~ m#<HTML><HEAD><TITLE>Journal of (.*?) \(\d+\)</TITLE>#
          or die "$uid does not exist";
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
        die "Cannot connect to " . UP_URL unless $content;

        $content =~ m#$user \((\d+)\)#ism
            or die "$user does not exist";
        $1;
    }
}

=head2 recentarray

Returns an array of the 30 most recently posted WWW::UsePerl::Journal::Entry objects

=cut

sub recentarray {
    my $self = shift;
    $self->{_recentarray} ||= do
    {
    my $content = $self->_journalsearch_content;
    die "Could not create search list - check your Internet connection" 
	    unless $content;

    my @entries;

# Sample of this on 04/10/2002
#<B><A HREF="//use.perl.org/~davorg/journal/8165">Buy More Books</A></B><BR>
#    <FONT SIZE="-1">On 2002.10.04  6:24</FONT><BR>
#    Yesterday I got my royalty statement for sales of Data Munging with Perl in the...<BR>
#    <FONT SIZE="-1">
#    Author: <A HREF="//use.perl.org/~davorg/">davorg</A>
#
#    </FONT>
#    <P>

    while ( $content =~ m#
        <B><A\s*HREF="$site/~(\w+)/journal/(\d+)">(.+?)</A></B><BR>
        \s*
        <FONT\s*SIZE="-1">On\s*(.+?)</FONT><BR>
        \s*
        .+?<BR>
        \s*
        <FONT\s*SIZE="-1">
        \s*
        Author:\s*<A\s*HREF="$site/~(\w+)/">(\w+)</A>
        \s*
        </FONT>
        \s*
        <P>
    #migxs ) {
        die "$5 is not $6" if $5 ne $6;
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

    $content =~ 
        s/^.*\Q<!-- start template: ID 251,
        journalsearch;search;default -->\E//sm;
    $content =~ 
        s/<A HREF=\"$site\/search\.pl\?threshold=0&op=journals
		&sort=1&amp;start=30">Next 30 matches&gt;
		<\/A>\s*<P>\s*
		<!-- end template: ID 251, journalsearch;search;default -->.*$//sm;

    return $content;
}

=head2 entryhash

Returns a hash of WWW::UsePerl::Journal::Entry objects

=cut

sub entryhash {
    my $self = shift;
    $self->{_entryhash} ||= do {
        my $UID = $self->uid;
        my $user = $self->user;

        my $content = $self->{ua}->request(
            GET UP_URL . "/journal.pl?op=list&uid=$UID")->content;
        die "could not create entry list" unless $content;

        my %entries;

        while ( $content =~ m#
            ~$user/journal/(\d+)"><b>(.*?)</b></a></td>
            [\s\r\n]*
            <[^<]+><em>
            ([^<]+)
            </em></[^<]+>
        #migxs ) {
            my $time = Time::Piece->strptime($3, '%Y.%m.%d %H:%M');
            #$time += 4*ONE_HOUR; # correct TZ?

            next unless defined $1;
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
list of comment IDs, {ascending=>1} to return an ascending list or 
{threaded=>1} to return a thread ordered list. The latter being the default.

=cut

sub entryids {
    my $self = shift;
	my $hash = shift;
	my ($key,$sorter) = ('_entryids_thd',sub{0});	# threaded
	($key,$sorter) = ('_entryids_asc',\&_ascender)	if(defined $hash && $hash->{ascending});
	($key,$sorter) = ('_entryids_dsc',\&_descender)	if(defined $hash && $hash->{descending});

	$self->{$key} ||= do {
        my %entries = $self->entryhash;
        my @IDs;

        foreach (sort $sorter keys %entries) {
            $IDs[$#IDs+1] = $_;
        }
        return @IDs;
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
	my ($key,$sorter) = ('_entrytitles_thd',sub{0});		# threaded
	($key,$sorter) = ('_entrytitless_asc',\&_ascender)	if(defined $hash && $hash->{ascending});
	($key,$sorter) = ('_entrytitles_dsc',\&_descender)	if(defined $hash && $hash->{descending});

	$self->{_entrytitles} ||= do {
        my %entries = $self->entryhash;
        my @titles;

        foreach (sort keys %entries) {
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
    my $ID = shift;
    my $entry = WWW::UsePerl::Journal::Entry->new(
        j     => $self,
        id    => $ID,
    );
    return $entry;
}

=head2 entrytitled

Returns the text of an entry, given an entry title

=cut

sub entrytitled {
    my $self = shift;
    my $title = shift;
    my %entries = $self->entryhash;
    foreach (sort keys %entries) {
        next unless $entries{$_}->subject =~ /$title/ism;
        return $self->entry($_);
    }
    die "$title does not exist";
}

=head2 login

Required before posting can occur, takes the password

=cut

sub login {
    my ($self, $passwd) = (@_);
    my $user = $self->user;
    my $login =
        $self->{ua}->request(
           GET UP_URL . "/users.pl?op=userlogin&unickname=$user&upasswd=$passwd"
        )->content;
    die "login failed" unless $login;
    return ( $login =~ /Welcome back $user/ism ) ? 1 : 0;
}

=head2 postentry

Posts an entry into a journal, given a title and the text of the entry

$j-E<gt>postentry({title =E<gt> "My journal is great", text =E<gt> "It really is"});

=cut

sub postentry {
    my $self = shift;
    my %params = (@_);
    # Validate parameters
    for (qw/text title/) {
        return undef unless exists $params{$_}
    }
    %params = (%postdefaults, %params);
    $params{comments} = $params{comments} ? 1 : 0;
    if ($params{type} !~ /^[1-4]$/) {
        die "Invalid post type.\n";
        carp "Invalid post type.\n";
        return undef;
    }
    if ($params{topic} !~ /^\d+$/) {
        die "Invalid journal topic.\n";
        carp "Invalid journal topic.\n";
        return undef;
    }
    if (length($params{title}) > 60) {
        die "Subject too long.\n";
        carp "Subject too long.\n";
        return undef;
    }
    # Post posting
    my $editwindow =
        $self->{ua}->request(
        GET 'http://use.perl.org/journal.pl?op=edit')->content;
    die "don't have an editwindow" unless $editwindow;
    my ($formkey) = ($editwindow =~ m/formkey"\s+VALUE="([^"]+)"/ism);
    die "No formkey!" unless defined $formkey;
    croak "No formkey!" unless defined $formkey;
    my %data = (
        id              => '',
        state           => 'editing',
        preview         => 'active',
        formkey         => $formkey,
        description     => $params{title},
        tid             => $params{topic},
        journal_discuss => $params{comments},
        article         => $params{text},
        posttype        => $params{type},
        op              => 'save',
    );
    my $post = $self->{ua}->request(
        POST 'http://use.perl.org/journal.pl', \%data);
        return $post->is_success;
}

# sort methods

sub _ascender { $a <=> $b }
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

Current maintainer is Barbie <barbie@cpan.org>, F<http://birmingham.pm.org>

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

