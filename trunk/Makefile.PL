use strict;

use ExtUtils::MakeMaker;
use vars qw( %conflicts );

sub conflicts {
    my ( $module, $version ) = @_;
    eval "use $module";
    my $module_version = eval "\$".$module."::VERSION";
    warn "\nWarning: This version of DateTime::Set conflicts with\n".
         "installed module \"$module\" Version $module_version\n\n"
        if defined $module_version && $module_version < $version;
}


%conflicts = (
                'DateTime::Event::Recurrence' => '0.10',
		'DateTime::Event::ICal'       => '0.07',
		'DateTime::Event::Random'     => '0.03',
		'DateTime::Event::Cron'       => '0.0601',
                'DateTime::Event::Sunrise'    => '0.0501',
		# 'DateTime-Event-Chinese'      => ''  -- test!
		# 'DateTime-Event-Lunar'        => ''
		# 'DateTime-Event-SolarTerm'    => '' 
);

for ( keys %conflicts ) 
{
    conflicts ( $_, $conflicts{$_} );
}

WriteMakefile( NAME         => 'DateTime::Set',
               VERSION_FROM => 'lib/DateTime/Set.pm',
               AUTHOR       => 'Flavio S. Glock <fglock@pucrs.br>',
               ABSTRACT     => 'DateTime set objects',

               PREREQ_PM    => { 'DateTime' => 0.12,
                                 'Set::Infinite' => 0.5503,
                                 'Test::More'  => 0,
                               },
             );
