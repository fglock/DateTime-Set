use strict;

use ExtUtils::MakeMaker;

WriteMakefile( NAME         => 'DateTime::Set',
               VERSION_FROM => 'lib/DateTime/Set.pm',
               AUTHOR       => 'Flavio S. Glock <fglock@pucrs.br>',
               ABSTRACT     => 'DateTime set objects',

               PREREQ_PM    => { 'DateTime' => 0.12,
                                 'Set::Infinite' => 0.5502,
                                 'Test::More'  => 0,
                               },
             );
