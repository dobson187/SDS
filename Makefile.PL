use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'SDS',
    AUTHOR              => q{Jason R Dobson <dobson187@gmail.com>},
    VERSION_FROM        => 'lib/SDS.pm',
    ABSTRACT_FROM       => 'lib/SDS.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'SDS-*' },
);
