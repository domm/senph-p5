package Senf::Object::Site;
use 5.026;

# ABSTRACT: a site

use Moose;
use MooseX::Types::URI qw(Uri);
use MooseX::Storage;

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

has 'status' => (
    is=>'ro',
    isa=>'Str', # TODO enum,
    required=>1,
    default=>'online'
);

# settings:
# allow_edit
# require_approval



__PACKAGE__->meta->make_immutable;
