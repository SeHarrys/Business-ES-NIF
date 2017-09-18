use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Business::ES::NIF',
    license             => 'artistic_2',
    dist_author         => q{Harun Delgado <hdp@djmania.es>},
    dist_abstract       => 'Check is valid Spanish NIF',
    dist_version_from   => 'lib/Business/ES/NIF.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Business::Tax::VAT::Validation' => 0,
    },
    add_to_cleanup     => [ 'Business-ES-NIF-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
