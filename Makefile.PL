use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'			=> 'WWW::UsePerl::Journal',
    'VERSION_FROM'	=> 'lib/WWW/UsePerl/Journal.pm',
    'PREREQ_PM'		=> { 
		LWP::UserAgent => 0,
		Test::Simple   => 0.40,
		Time::Piece    => 1.07,
		Test::More     => 0,
	},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT	=> 'Handles the retrieval of UsePerl journal entries.',
       AUTHOR	=> 'Barbie <barbie@cpan.org>') : ()),
);
