package Senf::Object::Site;
use 5.026;

# ABSTRACT: a site

use Moose;
use MooseX::Types::URI qw(Uri);
use MooseX::Storage;
use Moose::Util::TypeConstraints;

with Storage('format' => 'JSON', 'io' => 'AtomicFile');

has 'ident' => (
    is=>'ro',
    isa=>'Str',
    required=>1,
);

has 'url' => (
    is  => 'ro',
    isa => 'Str',
    required => 1,
    #isa=>Uri,
    #coerce=>1,
);

has 'name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'show_comments' => (
    is=>'ro',
    isa=>'Bool',
    default=>1,
);

has 'allow_comments' => (
    is=>'ro',
    isa=>'Bool',
    default=>1,
);

has 'require_approval' => (
    is=>'ro',
    isa=>'Bool',
    default=>0,
);

has 'allow_edit' => (
    is=>'ro',
    isa=>'Bool',
    default=>0,
);

__PACKAGE__->meta->make_immutable;
