package WWW::UsePerl::Journal;

=head1 NAME

WWW::UsePerl::Journal - use.perl.org journal tool

=cut

=head1 SYNOPSIS

  use WWW::UsePerl::Journal;
  my $journal = WWW::UsePerl::Journal->new('russell')
  print $journal->entrytitled("Text::Echelon");
  my @entries = $journal->entrytitles();

=cut

=head1 DESCRIPTION

Can list journal entries for a user.
Can display a specific journal entry.
Can post into a journal.

=cut

use strict;
use vars qw($VERSION);
use LWP::UserAgent;
use HTTP::Cookies;
use HTTP::Request::Common;
use Data::Dumper;
use Carp;
use WWW::UsePerl::Journal::Entry;


use constant UP_URL => 'http://use.perl.org';
my $site = '//use.perl.org';

my %postdefaults = (
    topic     => 34,
    comments  => 1,
    type      => 1,
);


$VERSION = '0.06';

=head2 new

use WWW::UsePerl::Journal;
my $j = WWW::UsePerl::Journal-E<gt>new('russell');

Creates an instance for the specified user.

=cut

sub new {
    my $class = shift;
    my $user  = shift or die "We need a user!";
    my $ua = LWP::UserAgent->new(env_proxy => 1);
    $ua->cookie_jar(HTTP::Cookies->new());
    my $self  = bless { 
        ($user =~ /^\d+$/ ? '_uid' : '_user') => $user,
        ua => $ua,
        }, $class;
    return $self;
}#new

=head2 user

Returns the username

=cut

sub user {
    my $self = shift;
    $self->{_user} ||= do {
        my $uid = $self->uid;

        my $content = $self->{ua}->request(GET UP_URL .  "/journal.pl?op=list&uid=$uid")->content;
        die "Cannot connect to " . UP_URL unless $content;

        $content =~ m#<HTML><HEAD><TITLE>(.*?)'s Journal</TITLE>#
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
}#getUID

=head2 recentarray

Returns an array of the 30 most recently posted WWW::UsePerl::Journal::Entry objects

=cut

sub recentarray
{
    my $self = shift;
    $self->{_recentarray} ||= do
    {
	my $UID = $self->uid;
	my $user = $self->user;

	my $content = $self->{ua}->request(
	    GET UP_URL . "/search.pl?op=journals"
	)->content;
	die "could not create search list" unless $content;

	$content =~ s/^.*\Q<!-- start template: ID 251, journalsearch;search;default -->\E//sm;
	$content =~ s/\Q<!-- end template: ID 251, journalsearch;search;default -->\E.*$//sm;

	my @entries;
	while ( $content =~ m#
	\Q<A HREF="\E$site/~(\w+)/journal/(\d+)">(.*?)</A>
	\s*
	\Q by <A HREF="\E$site/~(\w+)/">(\w+)</A>
	\s*
	\Q<FONT SIZE="2">on \E(.*?)\Q</FONT><BR>\E
	#xg )
	{
	    die "$1 is not $4" if $1 ne $4;
	    die "$1 is not $5" if $1 ne $5;
	    die "$4 is not $5" if $4 ne $5;

	    push @entries, WWW::UsePerl::Journal::Entry->new(
		j	=> $self,
		user	=> $1,
		id	=> $2,
		subject	=> $3,
		date	=> $6
	    );

	    #warn "Posting by $1 on $6 [ $3 ] ($2)\n";
	}

	return @entries;
    }
}#recentarray

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
        my @lines = split /\n/, $content;

        my %entries;
        foreach my $line (@lines){
            next unless $line =~ m#~$user/journal/#ism;
            $line =~ m#~$user/journal/(\d+)"><b>(.*?)</b></a>#ism;

            next unless defined $1;
	    $entries{$1} = WWW::UsePerl::Journal::Entry->new(
		j	=> $self,
		user	=> $user,
		id	=> $1,
		subject	=> $2,
	    );
        }

    return %entries;
    }
}#entryhash

=head2 entryids

Returns an array of the entry IDs

=cut

sub entryids {
    my $self = shift;
    $self->{_entryids} ||= do {
        my %entries = $self->entryhash;
        my @IDs;

        foreach (sort keys %entries) {
	    $IDs[$#IDs+1] = $_;
        }
        return @IDs;
    }
}#entryids

=head2 entrytitles

Returns an array of the entry titles

=cut

sub entrytitles {
    my $self = shift;
    $self->{_entrytitles} ||= do {
        my %entries = $self->entryhash;
        my @titles;

        foreach (sort keys %entries) {
            $titles[$#titles+1] = $entries{$_}->subject;
        }
        return @titles;
    }
}#entrytitles

=head2 entry

Returns the text of an entry, given an entry ID

=cut

sub entry {
    my $self = shift;
    my $ID = shift;
    my $entry = WWW::UsePerl::Journal::Entry->new(
	j	=> $self,
	id	=> $ID,
    );
    return $entry;
}#entry

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
}#entrytitled

=head2 login

Required before posting can occur, takes the password

=cut

sub login
{
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

sub postentry
{
    my $self = shift;
    my %params = (@_);
    # Validate parameters
    for (qw/text title/)
    {
	return undef unless exists $params{$_}
    }
    %params = (%postdefaults, %params);
    $params{comments} = $params{comments} ? 1 : 0;
    if ($params{type} !~ /^[1-4]$/)
    {
	die "Invalid post type.\n";
	carp "Invalid post type.\n";
	return undef;
    }
    if ($params{topic} !~ /^\d+$/)
    {
	die "Invalid journal topic.\n";
	carp "Invalid journal topic.\n";
	return undef;
    }
    if (length($params{title}) > 60)
    {
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
	    id  => '',
	    state   => 'editing',
	    preview => 'active',
	    formkey => $formkey,
	    description => $params{title},
	    tid => $params{topic},
	    journal_discuss => $params{comments},
	    article => $params{text},
	    posttype    => $params{type},
	    op  => 'save',
	);
	my $post = $self->{ua}->request(
	    POST 'http://use.perl.org/journal.pl', \%data);
	    return $post->is_success;
	}#postEntry

1;
__END__
=head1 AVAILABILITY

It should be available for download from
F<http://russell.matbouli.org/code/www-useperl-journal/>
or from CPAN

=head1 AUTHOR

Russell Matbouli E<lt>www-useperl-journal-spam@russell.matbouli.orgE<gt>

F<http://russell.matbouli.org/>

=head1 CONTRIBUTORS

Thanks to Iain Truskett, Richard Clampe, Simon Wilcox and Simon Wistow 
for sending patches.

=head1 TODO

Better error checking and test suite.

Comment retrieval.

Writing activities (modify, delete ...)

=head1 CAVEATS

Beware the stringification of WWW::UsePerl::Journal::Entry objects. 
They're still objects, they just happen to look the same as before when
you're printing them. Use -E<gt>content instead.

=head1 LICENSE

Distributed under GPL v2. See F<COPYING> included with this distibution.

=head1 SEE ALSO

F<http://use.perl.org/>

F<LWP>

=cut
