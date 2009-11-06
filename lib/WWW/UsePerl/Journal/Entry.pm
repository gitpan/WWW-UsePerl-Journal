package WWW::UsePerl::Journal::Entry;

use strict;
use warnings;

use vars qw($VERSION $AUTOLOAD);
$VERSION = '0.23';

#----------------------------------------------------------------------------

=head1 NAME

WWW::UsePerl::Journal::Entry - use.perl.org journal entry

=head1 DESCRIPTION

Do not use directly. See L<WWW::UsePerl::Journal> for details of usage.

=cut

# -------------------------------------
# Library Modules

use LWP::UserAgent;
use HTTP::Cookies;
use HTTP::Request::Common;
use Carp;
use Time::Piece;
use Time::Seconds;
use WWW::UsePerl::Journal;

# -------------------------------------
# Constants & Variables

my $UP_URL = 'http://use.perl.org';
use overload q{""}  => sub { $_[0]->stringify() };

my $UID = '
            <div \s+ class="title" \s+ id="user-info-title"> \s+
            <h4> \s+ (.*?) \s+ \((\d+)\) \s+ </h4> \s+ </div>
        ';

my %mons = (
	1  => 'January',
	2  => 'February',
	3  => 'March',
	4  => 'April',
	5  => 'May',
	6  => 'June',
	7  => 'July',
	8  => 'August',
	9  => 'September',
	10 => 'October',
	11 => 'November',
	12 => 'December',
);

# -------------------------------------
# The Public Interface

=head1 METHODS

=head2 new

  use WWW::UsePerl::Journal::Entry;
  my $j = WWW::UsePerl::Journal::Entry->new(%hash);

Creates an instance for a specific entry. The hash must contain values for
the keys 'j' (journal object), 'author' (entry author) and 'eid' (entry id).

=cut

sub new {
    my $class = shift;
    $class    = ref($class) || $class;
    my %opts = (@_);

    for(qw/j author eid/) {
    	return	unless(exists $opts{$_});
    }

#use Data::Dumper;
#print STDERR "\n#self->new: ".Dumper(\%opts);

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

=head2 eid

Returns the entry id for the current journal entry.

=cut

sub eid {
    my $self = shift;
    return $self->{eid};
}

=head2 The Accessors

The following accessor methods are available:

  date
  subject
  author
  uid
  content

All functions can be called to return the current value of the associated
object variable.

=cut

my %autosubs = map {$_ => 1} qw( date subject author uid content );

sub AUTOLOAD {
    my $self = $_[0];
	no strict 'refs';
	my $name = $AUTOLOAD;
	$name =~ s/^.*:://;
	return $self->{j}->error( "Unsupported accessor [$AUTOLOAD]")	unless($autosubs{$name});

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

=head2 raw

For debugging purposes.

=cut

sub raw {
    my $self   = shift;
    my $eid    = $self->{eid};
    my $author = $self->{author};
#print STDERR "\n#raw: URL=[". $UP_URL . "/~$author/journal/$eid]";
    return $self->{j}->{ua}->request(GET $UP_URL . "/~$author/journal/$eid")->content;
}


# -------------------------------------
# The Private Subs

# name:	_get_content
# args:	self .... the current object
# retv: content text
# desc: Given a uid and journal entry id, will retrieve a specific journal
#       entry and disassemble into component parts. returns the content text

sub _get_content {
    my $self   = shift;
    my $eid    = $self->{eid};
    my $author = $self->{author};

    return $self->{j}->error("author missing")  unless($author);

    my $content = $self->{j}->{ua}->request(GET $UP_URL . "/~$author/journal/$eid")->content;

#print STDERR "\n#e->_get_content: URL=[". $UP_URL . "/~$author/journal/$eid]";
#print STDERR "\n#content=[$content]\n";

    return $self->{j}->error("error getting entry") unless $content;
    return $self->{j}->error("$eid does not exist")
        if $content =~
        m#Sorry, there are no journal entries
        found for this user.</TD></TR></TABLE><P>#is;
    return $self->{j}->error("$eid does not exist")
        if $content =~ m!Sorry, the requested journal entries were not found.!is;

    ($author,$self->{uid}) = $content =~ m!$UID!six;
#print STDERR "\n#e->_get_content: UID=[". ($self->{uid}) ."]";

    ($self->{subject}) = $content =~ m!
        <div \s+ id="journalslashdot"> .*?
        <div \s+ class="title"> \s+
        <h3> \s* (.*?) \s* </h3>
        !six;

    # date/time fields
    my ($month, $day, $year, $hr, $mi, $amp) = $content =~ m!
        <div \s+ class="journaldate">\w+ \s+ (\w+) \s+ (\d+), \s+ (\d+)</div> .*?
        <div \s+ class="details">(\d+):(\d+) \s+ ([AP]M)</div>
        !six;

    unless($month && $day && $year) {
        (undef,$mi,$hr,$day,$month,$year) = localtime(time());
        $month = $mons{$month};
    }

    # just in case we can't get the time
    if($hr && $mi && $amp) {
        $hr += 12 if($amp eq 'PM');
        $hr = 0   if($hr == 24);
    } else {
        $hr ||= 0;
        $mi ||= 0;
    }

    # sometimes Time::Piece can't parse the date :(
    eval {
        $self->{date} = Time::Piece->strptime(
            "$month $day $year ${hr}:$mi",
            '%B %d %Y %H:%M'
        );
    };

    #$self->{date} += 4*ONE_HOUR; # correct TZ?

    $content =~ m! <div \s+ class="intro">\s*(.*?)\s*</div> !six;
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

=head1 SEE ALSO

L<WWW::UsePerl::Journal>,
F<http://use.perl.org/>

=head1 AUTHOR

  Original author: Russell Matbouli
  <www-useperl-journal-spam@russell.matbouli.org>,
  <http://russell.matbouli.org/>

  Current maintainer: Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2002-2004 Russell Matbouli.
  Copyright (C) 2005-2009 Barbie for Miss Barbell Productions.

  This module is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.

The full text of the licenses can be found in the F<Artistic> and
F<COPYING> files included with this module, or in L<perlartistic> and
L<perlgpl> in Perl 5.8.1 or later.

=cut

