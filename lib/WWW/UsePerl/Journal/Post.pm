package WWW::UsePerl::Journal::Post;

our $VERSION = '0.14';

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

  # delete an entry you don't want
  # WARNING: this is permanent!
  $post->deleteentry($eid);

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

#    print STDERR "\n#login=\n$login\n";
    return undef	if($login =~ /Forget your password/);
    return 1;
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
        return $self->_posterror("missing $_ field from postentry") unless exists $params{$_}
    }

    %params = (%postdefaults, %params);
    $params{comments} = $params{comments} ? 'enabled' : 'disabled';

    return $self->_posterror("Invalid post type.\n")		
        if ($params{type}  =~ /[^\d]/ || $params{type}  <  1 || 
                                         $params{type}  >  4);
    return $self->_posterror("Invalid journal topic.\n")	
        if ($params{topic} =~ /[^\d]/ || $params{topic} <  1 || 
                                         $params{topic} > 37 || 
                                         $params{topic} == 16);
    return $self->_posterror("Subject too long.\n")		
        if (length($params{title}) > 60);

    # Post posting
    my $editwindow =
        $self->{ua}->request(
        GET UP_URL . '/journal.pl?op=edit')->content;
    return $self->_posterror("Can't get an editwindow") unless $editwindow;

    my ($formkey) = ($editwindow =~ m/formkey"\s+VALUE="([^"]+)"/ism);
    return $self->_posterror("No formkey!") unless defined $formkey;

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
    return $self->_posterror("Failed LWP POST request") unless $post->is_success;
    return 1;
}

sub _posterror {
    my ($self,$text) = @_;
    $self->{posterror} = $text;
    return 0;
}

=head2 posterror

Returns the error string when a postentry fails (returns 0).

=cut

sub posterror {
    my $self = shift;
    $self->{posterror};
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
        GET UP_URL . '/journal.pl?op=removemeta&id=' . $eid)->content;
    return $self->_posterror("No response for deletion") unless $content;

    $content =
        $self->{ua}->request(
        GET UP_URL . '/journal.pl?op=remove&del_' . $eid . '=1')->content;
    return $self->_posterror("No response for deletion") unless $content;

#    print STDERR "\n#content=\n$content\n";
}

1;
__END__

=head1 BUGS, PATCHES & FIXES

If you spot a bug or are experiencing difficulties, that is not explained 
within the POD documentation, please send an email to barbie@cpan.org or 
submit a bug to the RT system (http://rt.cpan.org/). However, it would help 
greatly if you are able to pinpoint problems or even supply a patch. 

Fixes are dependant upon their severity and my availablity. Should a fix not
be forthcoming, please feel free to (politely) remind me.

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

Barbie <barbie@cpan.org>, F<http://birmingham.pm.org>

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2005      Barbie for Miss Barbell Productions.
  All Rights Reserved.

  Distributed under GPL v2. See F<COPYING> included with this distibution.

=cut

