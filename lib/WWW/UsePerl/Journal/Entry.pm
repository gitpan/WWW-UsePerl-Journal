package WWW::UsePerl::Journal::Entry;

=head1 NAME

WWW::UsePerl::Journal::Entry - use.perl.org journal entry

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

our $VERSION = '0.05';
use constant UP_URL => 'http://use.perl.org';
use overload q{""} => sub { $_[0]->stringify() };

sub stringify {
    my $self = shift;
    $self->content();
}

sub new
{
    my $class = shift;
    $class = ref($class) || $class;

    my %defaults = (
	j	    => undef,
	id	    => undef,
	user	=> undef,
	subject	=> undef,
	content	=> undef,
	date    => undef,
    );
    my %opts = (@_);


    die "No parent object" unless exists $opts{j} and $opts{j}->isa('WWW::UsePerl::Journal');

    my $self = bless {%defaults, %opts}, $class;

    return $self;
}

sub id
{
    my $self = shift;
    $self->{id} = $_[0] if (@_);
    return $self->{id};
}

sub date
{
    my $self = shift;
    unless ($self->{date})
    {
        $self->get_content();
    }
    return $self->{date};
}

sub subject
{
    my $self = shift;
    $self->{subject} = $_[0] if (@_);
    return $self->{subject};
}

sub user
{
    my $self = shift;
    $self->{user} = $self->{j}->user(@_) unless defined $self->{user};
    $self->{user}
}

=head2 $id = $e->uid($id)

Either sets or returns the id of the user of the entry. If no user is
set then it uses the user of the parent journal.

=cut

sub uid
{
    my $self = shift;
    if (@_)
    {
	$self->{uid} = $_[0];
    }
    else
    {
	my $user = $self->user;
	if ($user ne $self->{j}->user)
	{

	    my $content = $self->{j}->{ua}->request(GET UP_URL . "/~$user/")->content;
	    die "Cannot connect to " . UP_URL unless $content;

	    $content =~ m#User info for $user \((\d+)\)#ism
		or die "$user does not exist";

	    $self->{uid} = $1;
	}
	else
	{
	    $self->{uid} = $self->{j}->uid;
	}
    }
    $self->{uid};
}

sub content
{
    my $self = shift;
    $self->{content} = $_[0] if (@_);
    $self->{content} = $self->get_content unless defined $self->{content};
    $self->{content};
}

sub get_content
{
    my $self = shift;
    my $ID = $self->{id};
    my $UID = $self->uid;
    my $content = $self->{j}->{ua}->request(
	GET UP_URL . "/journal.pl?op=display&uid=$UID&id=$ID"
    )->content;
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
