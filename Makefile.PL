use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'WWW::UsePerl::Journal',
    'VERSION_FROM' => 'lib/WWW/UsePerl/Journal.pm', # finds $VERSION
    'PREREQ_PM'    => { 
                       LWP::UserAgent => 0,
                       Test::Simple => 0.40,
                       Time::Piece  => 1.07,
                      },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/WWW/UsePerl/Journal.pm', # retrieve abstract from module
       AUTHOR     =>
       'Russell Matbouli <www-useperl-journal-makefile@russell.matbouli.org>') : ()),


);
