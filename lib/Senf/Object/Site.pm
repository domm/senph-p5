package Senf::Object::Site;
use 5.026;
use Moose;
use MooseX::Types::URI qw(Uri);

# ABSTRACT: a site

has 'url' => (
    is  => 'ro',
    isa => Uri,
);

has 'name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

__PACKAGE__->meta->make_immutable;
