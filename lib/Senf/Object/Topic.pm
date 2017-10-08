package Senf::Object::Topic;
use 5.026;

# ABSTRACT: a topic

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
    isa => 'Str', # Uri,
    required=>1,
);

has 'status' => (
    is=>'ro',
    isa=>'Str', # Enum (enabled, disabled)
    required=>1,
);

has 'comments'=> (
    is=>'ro',
    isa=>'ArrayRef',
    traits  => ['Array'],
    default=>sub {[]},
    handles => {
            all_comments    => 'elements',
            add_comment     => 'push',
            comment_count  => 'count',
        }
);

__PACKAGE__->meta->make_immutable;
