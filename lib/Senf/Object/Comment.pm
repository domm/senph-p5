package Senf::Object::Comment;
use 5.026;

# ABSTRACT: a comment

use Moose;
use MooseX::Storage;

with Storage('format' => 'JSON', 'io' => 'AtomicFile');

has 'ident' => (
    is=>'ro',
    isa=>'Str',
    required=>1,
);

has ['subject','comment'] => (
    is=>'ro',
    isa=>'Str',
    required=>1,
);

has 'created' => (
    is=>'ro',
    isa=>'Str', # TODO some kind of date
    required=>1, # TODO build/default
);

has 'reply_to' => (
    is=>'ro',
    isa=>'Str',
);

has 'status' => (
    is=>'ro',
    isa=>'Str', # TODO enum(draft, pending, online, deleted)
);

has 'secret' => (
    is=>'ro',
    isa=>'Str',
    default=>'s3cr3t', # TODO random
);

# TODO format?

#user
#user.name
#user.email
#user.url
#user.notify enum(replies, all)
#user.optin

__PACKAGE__->meta->make_immutable;
