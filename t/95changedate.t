use Test::More;
use IO::File;
use WWW::UsePerl::Journal;

# Skip if doing a regular install
plan skip_all => "Author tests not required for installation"
    unless ( $ENV{AUTOMATED_TESTING} );

my $fh = IO::File->new('Changes','r')   or plan skip_all => "Cannot open Changes file";

plan no_plan;

my $latest = 0;
while(<$fh>) {
    next        unless(m!^\d!);
    $latest = 1 if(m!^$WWW::UsePerl::Journal::VERSION!);
    like($_, qr!(   
                    \d[\d._]+\s+\d{2}/\d{2}/\d{4}                           | # 05/03/2007
                    \w+\s+\w+\s+\d{1,2}\s+\d{2}:\d{2}:\d{2}\s+\w+\s+\d{4}   | # Fri Jan 24 15:11:53 GMT 2003
                    (\w+\s+)?\w+\s+\d{1,2}                                  ) # Tue Apr 05 2005   OR   Apr 05 2005
                !x,'... version has a date');
}

is($latest,1,'... latest version not listed');
