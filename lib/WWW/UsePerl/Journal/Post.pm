package WWW::UsePerl::Journal::Post;

our $VERSION = '0.13';

#----------------------------------------------------------------------------

=head1 NAME

WWW::UsePerl::Journal::Post - use.perl.org journal post tool

=head1 SYNOPSIS

  use WWW::UsePerl::Journal::Post;
  my $post = WWW::UsePerl::Journal::Post->new(
    username => $user,
    password => $pass
  );

  # basic post using defaults
  $post->postentry(title => 'title', text => 'text');
  
  # post entry overriding defaults
  $post->postentry(
    title    => 'title',
    text     => 'text',
    topic    => 34,
    comments => 1,
    type     => 1
  );

=head1 DESCRIPTION

Allows users to post a use.perl entry to their journal.

=cut

# -------------------------------------
# Library Modules

use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Cookies;
use HTTP::Request::Common;
use Carp;

# -------------------------------------
# Constants & Variables

use constant UP_URL => 'http://use.perl.org';

my %postdefaults = (
    topic     => 34,
    comments  => 1,
    type      => 1,
);

# -------------------------------------
# The Public Interface

=head1 METHODS

=head2 new

Creates an instance for the specified user.

=cut

sub new {
    my $class = shift;
    my $hash  = shift;

    for(qw/username password/) {
    	return undef	unless($hash->{$_});
    }

    my $ua    = LWP::UserAgent->new(env_proxy => 1);
    $ua->cookie_jar(HTTP::Cookies->new());

    $hash->{ua} = $ua;

    my $self  = bless { %$hash }, $class;
    return undef	unless($self->login);
    return $self;
}

sub DESTROY {}

=head2 login

Performs the login.

=cut

sub login {
    my $self = shift;

    my $login =
        $self->{ua}->request(
           GET UP_URL . "/users.pl?op=userlogin&" .
	   "unickname=$self->{username}&" .
	   "upasswd=$self->{password}"
        )->content;

    return undef	unless $login;
    return $login;
}

=head2 postentry

Posts an entry into a journal, given a title and the text of the entry

  $j->postentry({title => "My journal is great", text => "It really is"});

=cut

sub postentry {
    my $self = shift;
    my %params = (@_);

    # Validate parameters
    for (qw/text title/) {
        die "missing $_ field from postentry" unless exists $params{$_}
    }

    %params = (%postdefaults, %params);
    $params{comments} = $params{comments} ? 1 : 0;
    carp "Invalid post type.\n"		if ($params{type} !~ /^[1-4]$/);
    carp "Invalid journal topic.\n"	if ($params{topic} !~ /^\d+$/);
    carp "Subject too long.\n"		if (length($params{title}) > 60);

    # Post posting
    my $editwindow =
        $self->{ua}->request(
        GET UP_URL . '/journal.pl?op=edit')->content;
    carp "Can't get an editwindow" unless $editwindow;

    my ($formkey) = ($editwindow =~ m/formkey"\s+VALUE="([^"]+)"/ism);
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
    my $post = $self->{ua}->request(POST UP_URL . '/journal.pl', \%data);
    return $post->is_success;
}

=head2 deleteentry

Deletes an entry from a journal, given the entry id.

  $j->deleteentry($eid);

=cut

sub deleteentry {
    my ($self,$eid) = @_;

    my $content =
        $self->{ua}->request(
        GET UP_URL . '/journal.pl?op=removemeta&id=' . $eid)->content;
    carp "No response for deletion" unless $content;

    $content =
        $self->{ua}->request(
        GET UP_URL . '/journal.pl?op=remove&del_' . $eid . '=1')->content;
    carp "No response for deletion" unless $content;
}

1;
__END__

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties, that is not explained within the POD
documentation, please send an email to barbie@cpan.org or submit a bug to the
RT system (http://rt.cpan.org/). However, it would help greatly if you are 
able to pinpoint problems or even supply a patch. 

Fixes are dependant upon their severity and my availablity. Should a fix not
be forthcoming, please feel free to (politely) remind me.

=head1 SEE ALSO

L<WWW::UsePerl::Journal>,
F<http://use.perl.org/>

=head1 AUTHOR

Barbie <barbie@cpan.org>, F<http://birmingham.pm.org>

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2005      Barbie for Miss Barbell Productions.
  All Rights Reserved.

  Distributed under GPL v2. See F<COPYING> included with this distibution.

=cut

