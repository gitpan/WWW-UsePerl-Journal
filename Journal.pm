package WWW::UsePerl::Journal;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use LWP::Simple;

require Exporter;

@ISA = qw(Exporter);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw( );
$VERSION = '0.01';


# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

sub new {
    my $class = shift;
    my $self  = bless {}, $class;
    return $self;
}#new
  
sub getUID {
    my $self = shift;
    my $user = shift;

    print "getUID: user not stated\n" unless $user;
    return unless $user;

    my $content = get("http://use.perl.org/~$user/");
    return unless $content;

    $content =~ s/.*User info for $user \((\d+)\).*/$1/ism;
    return unless $content;

    return $content;
}#getUID

sub getEntryList {
    my $self = shift;
    my $user = shift;

    my $UID = getUID($self, $user);
    return unless $UID;

    my $content = get("http://use.perl.org/journal.pl?op=list&uid=$UID");
    return unless $content;
    my @lines = split /\n/, $content;

    my @entries = ();
    foreach my $line (@lines){
        next unless $line =~ /journal\.pl\?op=display&amp;uid=$UID/;
        $line =~ 
          s/.*?use\.perl\.org\/journal\.pl\?op=display
          &amp;uid=$UID&amp;id=(\d*)"><b>(.*?)<\/b><\/a>.*
          /$1, $2/ix;
        $entries[$#entries+1] = $line;
    }

    return @entries;
}#getEntryList

sub getEntryIDs {
    my $self = shift;
    my $user = shift;

    my @entries = getEntryList($self, $user);
    my @IDs;

    foreach (@entries) {
    my ($id, $text) = split /, /;
    $IDs[$#IDs+1] = $id;
    }
    return @IDs;
}#getEntryIDs

sub getEntryTitles {
    my $self = shift;
    my $user = shift;

    my @entries = getEntryList($self, $user);
    my @titles;

    foreach (@entries) {
    my ($id, $text) = split /, /;
    $titles[$#titles+1] = $text;
    }
    return @titles;
}#getEntryTitles

sub getEntryByID {
    my $self = shift;
    my $user = shift;
    my $ID = shift;

    my $UID = getUID($self, $user);

    my $content = get("http://use.perl.org/journal.pl?op=display&uid=$UID&id=$ID");
    return "Sorry, this journal entry does not exist" 
      if $content =~ 
      m#Sorry, there are no journal entries found for this user.</TD></TR></TABLE><P>#;
    $content =~ 
      s#.*?$ID</a>\n]\n\s*</font>\n\s*<p>\n\s*(.*?)
      \n\s*<br><br></div>.*#$1#ismx;
    return $content;
}#getEntryByID

sub getEntryByTitle {
    my $self = shift;
    my $user = shift;
    my $title = shift;
    my @entries = getEntryList($self, $user);
    my @ID = grep /$title/, @entries;
    return unless defined $#ID;
    my ($id, $d) = split /, /, $#ID;

    return getEntryByID($self, $user, $id);
}#getEntryByTitle

1;
__END__
=head1 NAME

WWW::UsePerl::Journal - use.perl.org journal tool

=head1 SYNOPSIS

  use WWW::UsePerl::Journal;
  my $journal = WWW::UsePerl::Journal->new()
  print $journal->getEntryByTitle("russell", "Text::Echelon");
  my @entries = $journal->getEntryTitles("russell");

=head1 DESCRIPTION

Lists journal entries for a user. Can display a specific journal entry.

=head1 AVAILABILITY

It should be available for download from
F<http://russell.matbouli.org/code/www-useperl-journal/>
or from CPAN

=head1 AUTHOR

Russell Matbouli E<lt>www-useperl-journal-spam@russell.matbouli.orgE<gt>

F<http://russell.matbouli.org/>

=head1 TODO

Optimise via caching - this will be in the next proper release I hope.

Better error checking.

Comment retrieval

Writing activities (comments, create entry, modify, delete ...)

=head1 LICENSE

Distributed under GPL v2. See COPYING included with this distibution.

=head1 SEE ALSO

http://use.perl.org/

=cut
