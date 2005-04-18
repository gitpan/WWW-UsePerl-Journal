package WWW::UsePerl::Journal::Entry;

=head1 NAME

WWW::UsePerl::Journal::Entry - use.perl.org journal entry

=head1 DESCRIPTION

Do not use directly. See L<WWW::UsePerl::Journal> for details of usage.

=cut

use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Cookies;
use HTTP::Request::Common;
use Data::Dumper;
use Carp;
use Time::Piece;
use Time::Seconds;
use WWW::UsePerl::Journal;

our $VERSION = '0.06';
use constant UP_URL => 'http://use.perl.org';
use overload q{""}  => sub { $_[0]->stringify() };

=head1 METHODS

=head2 stringify

  use WWW::UsePerl::Journal::Entry;
  my $j = WWW::UsePerl::Journal::Entry->new(%hash);
  print "$j";

Returns the content of the journal entry when the object is directly referenced
in a string.

=cut

sub stringify {
    my $self = shift;
    $self->content();
}

=head2 new

  use WWW::UsePerl::Journal::Entry;
  my $j = WWW::UsePerl::Journal::Entry->new(%hash);

Creates an instance for a specific entry.

=cut

sub new {
    my $class = shift;
    $class = ref($class) || $class;

    my %defaults = (
        j       => undef,
        id      => undef,
        user    => undef,
        subject => undef,
        content => undef,
        date    => undef,
    );
    my %opts = (@_);


    die "No parent object" 
	    unless exists $opts{j} and $opts{j}->isa('WWW::UsePerl::Journal');

    my $self = bless {%defaults, %opts}, $class;

    return $self;
}

=head2 id

Accessor for the entry id.

=cut

sub id {
    my $self = shift;
    $self->{id} = $_[0] if (@_);
    return $self->{id};
}

=head2 date

Returns the date for the current journal entry.

=cut

sub date {
    my $self = shift;
    unless ($self->{date}) {
        $self->get_content();
    }
    return $self->{date};
}

=head2 subject

Accessor for the subject of the current journal entry.

=cut

sub subject {
    my $self = shift;
    $self->{subject} = $_[0] if (@_);
    return $self->{subject};
}

=head2 user

Accessor for the user of the current journal entry.

=cut

sub user {
    my $self = shift;
    $self->{user} = $self->{j}->user(@_) 
	    unless defined $self->{user};
    $self->{user}
}

=head2 uid

  $id = $e->uid($id)

Either sets or returns the id of the user of the entry. If no user is
set then it uses the user of the parent journal.

=cut

sub uid {
    my $self = shift;
    if (@_) {
        $self->{uid} = $_[0];
    } else {
        my $user = $self->user;
        if ($user ne $self->{j}->user) {

            my $content = $self->{j}->{ua}->request(GET UP_URL 
		        . "/~$user/")->content;
            die "Cannot connect to " . UP_URL unless $content;

            $content =~ m#User info for $user \((\d+)\)#ism
                or die "$user does not exist";

            $self->{uid} = $1;
        } else {
            $self->{uid} = $self->{j}->uid;
        }
    }
    $self->{uid};
}

=head2 content

Accessor for the content of the current journal entry.

=cut

sub content {
    my $self         = shift;
    $self->{content} = $_[0] if (@_);
    $self->{content} = $self->get_content 
        unless defined $self->{content};
    $self->{content};
}

=head2 get_content

Given a uid and journal entry id, will retrieve a specific journal entry and
disassemble into component parts.

=cut

sub get_content {
    my $self    = shift;
    my $ID      = $self->{id};
    my $UID     = $self->uid;
    my $content = $self->{j}->{ua}->request(
        GET UP_URL . "/journal.pl?op=display&uid=$UID&id=$ID")->content;
    die "error getting entry" unless $content;
    die "$ID does not exist" 
        if $content =~ 
        m#Sorry, there are no journal entries 
        found for this user.</TD></TR></TABLE><P>#ismx;

    my ($month, $day, $year, $hr, $mi, $amp) = $content =~ m!
      <[hH]2> \w+ \s+ (\w+) \s+ (\d+), \s+ (\d+) </[hH]2>
      .*?
      (\d+):(\d+) \s+ ([AP]M)
    !smx;
    $hr += 12 if ($amp eq 'PM');
    $hr = 0 if $hr == 24;

    $self->{date} = Time::Piece->strptime(
        "$month $day $year ${hr}:$mi",
        '%B %d %Y %H:%M'
    );
    #$self->{date} += 4*ONE_HOUR; # correct TZ?


    $content =~ 
        m#.*?$ID</a>\n]\n\s*</font>\n\s*<p>\n\s*(.*?)
        \n\s*<br><br></div>.*#ismx;
    return $1;
}


1;
__END__

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

F<LWP>,
L<WWW::UsePerl::Journal>

=head1 AUTHOR

Original author was Russell Matbouli 
E<lt>www-useperl-journal-spam@russell.matbouli.orgE<gt>, 
F<http://russell.matbouli.org/>

Current maintainer is Barbie <barbie@cpan.org>, F<http://birmingham.pm.org>

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2002-2004 Russell Matbouli.
  Copyright (C) 2005      Barbie for Miss Barbell Productions.
  All Rights Reserved.

  Distributed under GPL v2. See F<COPYING> included with this distibution.

=cut

