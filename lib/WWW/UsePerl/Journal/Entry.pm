package WWW::UsePerl::Journal::Entry;

use vars qw($AUTOLOAD);
our $VERSION = '0.14';

#----------------------------------------------------------------------------

=head1 NAME

WWW::UsePerl::Journal::Entry - use.perl.org journal entry

=head1 DESCRIPTION

Do not use directly. See L<WWW::UsePerl::Journal> for details of usage.

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
use Time::Seconds;
use WWW::UsePerl::Journal;

# -------------------------------------
# Constants & Variables

use constant UP_URL => 'http://use.perl.org';
use overload q{""}  => sub { $_[0]->stringify() };

# -------------------------------------
# The Public Interface

=head1 METHODS

=head2 new

  use WWW::UsePerl::Journal::Entry;
  my $j = WWW::UsePerl::Journal::Entry->new(%hash);

Creates an instance for a specific entry.

=cut

sub new {
    my $class = shift;
    $class    = ref($class) || $class;
    my %opts = (@_);
    
    for(qw/j id/) {
    	return undef	unless(exists $opts{$_});
    }

    my $self = bless {%opts}, $class;
    return $self;
}

sub DESTROY {}

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

=head2 id

Returns the entry id for the current journal entry.

=cut

sub id {
    my $self = shift;
    return $self->{id};
}

=head2 The Accessors

The following accessor methods are available:

  date  
  subject  
  user
  uid
  content

All functions can be called to return the current value of the associated
object variable.

=cut

my @autosubs = qw( date subject user uid content );
my %autosubs = map {$_ => 1} @autosubs;

sub AUTOLOAD {
	no strict 'refs';
	my $name = $AUTOLOAD;
	$name =~ s/^.*:://;
	carp "Unknown sub $AUTOLOAD\n"	unless($autosubs{$name});
	
	*$name = sub {
			my $self = shift;
			$self->_get_content()	unless($self->{$name});
			return unless($self->{$name});
			$self->{$name} =~ s/^\s+//;					# remove leading whitespace
			$self->{$name} =~ s/\s+$//;					# remove trailing whitespace
			return $self->{$name};
	};
	goto &$name;
}

# -------------------------------------
# The Private Subs

# name:	_get_content
# args:	self .... the current object
# retv: content text
# desc: Given a uid and journal entry id, will retrieve a specific journal 
#       entry and disassemble into component parts. returns the content text

sub _get_content {
    my $self      = shift;
    my $eid       = $self->{id};
    $self->{uid}  = $self->{j}->uid;
    $self->{user} = $self->{j}->user;

    my $content = $self->{j}->{ua}->request(
        GET UP_URL . "/journal.pl?op=display&uid=$self->{uid}&id=$eid")->content;

#print STDERR "\n#e->_get_content: URL=[". UP_URL . "/journal.pl?op=display&uid=$self->{uid}&id=$eid]";
#print STDERR "\n#content=[$content]\n";

    carp "error getting entry" unless $content;
    carp "$eid does not exist" 
        if $content =~ 
        m#Sorry, there are no journal entries 
        found for this user.</TD></TR></TABLE><P>#is;
    carp "$eid does not exist" 
        if $content =~ m!Sorry, the requested journal entries were not found.!is;


    ($self->{subject}) = $content =~ m!
        <div \s+ id="journalslashdot"> .*?
        <div \s+ class="title"> \s+ 
        <h3> \s+ (.*?) \s+ </h3> \s+ </div>
        !six;

    # date/time fields
    my ($month, $day, $year) = $content =~ m!
        <div \s+ class="journaldate">\w+ \s+ (\w+) \s+ (\d+), \s+ (\d+)</div>
        !six;
    my ($hr, $mi, $amp) = $content =~ m!
        <div \s+ class="details">(\d+):(\d+) \s+ ([AP]M)</div>
        !six;

    $hr += 12 if ($amp eq 'PM');
    $hr = 0 if $hr == 24;

    $self->{date} = Time::Piece->strptime(
        "$month $day $year ${hr}:$mi",
        '%B %d %Y %H:%M'
    );
    #$self->{date} += 4*ONE_HOUR; # correct TZ?

    $content =~ m! 
        <div \s+ class="intro">\s*(.*?)\s*</div>
    !six;
    $self->{content} = $1;
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

L<WWW::UsePerl::Journal>,
F<http://use.perl.org/>

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

