package WWW::UsePerl::Journal::Post;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.23';

#----------------------------------------------------------------------------

=head1 NAME

WWW::UsePerl::Journal::Post - use.perl.org journal post tool

=head1 DESCRIPTION

Allows users to post a use.perl entry to their journal.

=head1 SYNOPSIS

Note that this module is not meant to be called directly. You should access the
undelying object as follows:

  use WWW::UsePerl::Journal;
  my $j = WWW::UsePerl::Journal->new($user);
  my $post = $j->login($pass);

However, you can access the object directly as follows:

  use WWW::UsePerl::Journal;
  my $j = WWW::UsePerl::Journal->new($user);

  use WWW::UsePerl::Journal::Post;
  my $post = WWW::UsePerl::Journal::Post->new(
    j        => $j,
    username => $user,
    password => $pass
  );

  # basic post using defaults
  my $success = $post->postentry(title => 'title', text => 'text');

  # post entry overriding defaults
  $success = $post->postentry(
    title    => 'title',
    text     => 'text',
    topic    => 34,
    comments => 1,
    type     => 1
    promote  => 'publish',
  );

  # delete an entry you don't want
  # WARNING: this is permanent!
  $success = $post->deleteentry($eid);

=cut

# -------------------------------------
# Library Modules

use LWP::UserAgent;
use HTTP::Cookies;
use HTTP::Request::Common;
use Carp;

# -------------------------------------
# Constants & Variables

my $UP_URL = 'http://use.perl.org';

my %postdefaults = (
    topic    => 34,
    comments => 1,
    type     => 1,
    promote  => 'publish',
);

# -------------------------------------
# The Public Interface

=head1 METHODS

=head2 new

Creates an instance for the specified user.

=cut

sub new {
    my $class = shift;
    my %hash  = @_;

    for(qw/j username password/) {
    	return	unless($hash{$_});
    }

    my $ua    = LWP::UserAgent->new(env_proxy => 1);
    $ua->cookie_jar(HTTP::Cookies->new());

    $hash{ua} = $ua;

    my $self  = bless { %hash }, $class;
    return	unless($self->login);
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
           GET $UP_URL . "/users.pl?op=userlogin&unickname=$self->{username}&upasswd=$self->{password}"
        )->content;

    return 1    if($login && $login =~ m{\QThis is <b>your</b> User Info page}i);
    return;
}

=head2 postentry

Posts an entry into a journal, given a title and the text of the entry

  $j->postentry(title => "My journal is great", text => "It really is");

=cut

sub postentry {
    my $self = shift;
    my %params = (@_);

    # Validate parameters
    for (qw/text title/) {
        return $self->{j}->error("missing $_ field from postentry")
            unless exists $params{$_};
    }

    %params = (%postdefaults, %params);
    $params{comments} = $params{comments} ? 'enabled' : 'disabled';

    return $self->{j}->error("Invalid post type.")
        if ($params{type}  =~ /[^\d]/ || $params{type}  <  1 ||
                                         $params{type}  >  4);
    return $self->{j}->error("Invalid journal topic.")
        if ($params{topic} =~ /[^\d]/ || $params{topic} <  1  ||
                                         $params{topic} == 16 ||
                                         ($params{topic} > 37 && $params{topic} != 44));
    return $self->{j}->error("Invalid promotion type.")
        if ($params{promote} !~ /(publish|publicize|post)/);
    return $self->{j}->error("Subject too long.")
        if (length($params{title}) > 60);

    # Post posting
    my $editwindow =
        $self->{ua}->request(
        GET $UP_URL . '/journal.pl?op=edit')->content;
    return $self->{j}->error("Can't get an editwindow") unless $editwindow;

    my ($formkey) = ($editwindow =~ m/reskey"\s+value="([^"]+)"/ism);
    return $self->{j}->error("No formkey!") unless defined $formkey;

#promotetype" value="publish|publicize|post

    my %data = (
        id              => '',
        state           => 'editing',
        preview         => 'active',
        reskey          => $formkey,
        description     => $params{title},
        tid             => $params{topic},
        journal_discuss => $params{comments},
        article         => $params{text},
        posttype        => $params{type},
        promotetype     => $params{promote},
        op              => 'save',
    );

    sleep 5;
    my $post = $self->{ua}->request(POST $UP_URL . '/journal.pl', \%data);

    return $self->{j}->error("Failed LWP POST request") unless $post->is_success;
    return $self->{j}->error("Got the wait a little bit message") if $post->content =~ /wait a little bit/;

    return 1;
}

=head2 deleteentry

Deletes an entry from a journal, given the entry id.

  $j->deleteentry($eid);

NOTE: This currently doesn't work!

=cut

sub deleteentry {
    my ($self,$eid) = @_;

    my $content =
        $self->{ua}->request(
        GET $UP_URL . '/journal.pl?op=removemeta&id=' . $eid)->content;
    return $self->{j}->error("No response for deletion") unless $content;

    my ($formkey) = ($content =~ m/reskey"\s+value="([^"]+)"/ism);
    return $self->{j}->error("Unable to delete entry.") unless defined $formkey;

    my %data = (
        reskey => $formkey,
        op     => 'remove',
    );
    $data{'del_'.$eid} = 1;

    my $post = $self->{ua}->request(POST $UP_URL . '/journal.pl', \%data);
    return $self->{j}->error("No response for deletion") unless $post->is_success;

    # Note:
    # I was trying to verify that an entry was deleted, but the code below
    # results in the entry coming back!

#    $content = $post->content;
#    print STDERR "\n#content=\n$content\n";
#    return $self->{j}->error("Jounal entries found!")
#        unless($content =~ /You have not created any journal entries.|Sorry, the requested journal entries were not found./);

    return 1;
}

1;
__END__

=head1 SUPPORT

If you spot a bug or are experiencing difficulties that are not explained
within the POD documentation, please submit a bug to the RT system (see link
below). However, it would help greatly if you are able to pinpoint problems or
even supply a patch.

Fixes are dependant upon their severity and my availablity. Should a fix not
be forthcoming, please feel free to (politely) remind me by sending an email
to barbie@cpan.org .

RT: L<http://rt.cpan.org/Public/Dist/Display.html?Name=WWW-UsePerl-Journal>

=head2 Known Bugs

=over 4

=item * deleteentry

It appears that although the request to delete an entry is correct, there
is obviously something I'm missing, because it doesn't actually get deleted
from the use.perl system :(

=back

=head1 SEE ALSO

L<WWW::UsePerl::Journal>,
F<http://use.perl.org/>

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2003-2009 Barbie for Miss Barbell Productions.

  This module is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.

The full text of the licenses can be found in the F<Artistic> and
F<COPYING> files included with this module, or in L<perlartistic> and
L<perlgpl> in Perl 5.8.1 or later.

=cut
