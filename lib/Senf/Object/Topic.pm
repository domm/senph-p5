package Senf::Object::Topic;
use 5.026;

# ABSTRACT: a topic

use Moose;
use MooseX::Types::URI qw(Uri);
use MooseX::Storage;

with Storage( 'format' => 'JSON', 'io' => 'AtomicFile' );

# TODO: rework storage
# topic-ident should be url (without protocol), based on url we calc sha1 and use this to store the json; maybe add a site/map.json mapping urls to sha1-files (mostly for humans, the code will just calc the sha1 again)
# maybe ditch MooseX::Storage?
# maybe add site as an attribute to topic? so we don't have to pass two objects around?

has 'url' => (
    is       => 'ro',
    isa      => 'Str',    # Uri,
    required => 1,
);

has 'comments' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    traits  => ['Array'],
    default => sub { [] },
    handles => {
        all_comments  => 'elements',
        add_comment   => 'push',
        comment_count => 'count',
    }
);

has 'show_comments' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1,
);

has 'allow_comments' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1,
);

has 'require_approval' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

__PACKAGE__->meta->make_immutable;
