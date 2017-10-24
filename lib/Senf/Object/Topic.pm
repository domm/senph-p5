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
