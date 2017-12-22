package Senph::Object::Site;
use 5.026;

# ABSTRACT: a site

use Moose;
use MooseX::Types::URI qw(Uri);
use MooseX::Storage;
use Moose::Util::TypeConstraints;

with Storage( 'format' => 'JSON', 'io' => 'AtomicFile' );

has 'url' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,

    #isa=>Uri,
    #coerce=>1,
);

has 'name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'default_show_comments' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1,
);

has 'default_allow_comments' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1,
);

has 'default_require_approval' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has 'global_show_comments' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1,
);

has 'global_allow_comments' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1,
);

has 'global_require_approval' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

__PACKAGE__->meta->make_immutable;
