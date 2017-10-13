package Senf::Object::Comment;
use 5.026;

# ABSTRACT: a comment

use Moose;
use MooseX::Storage;

use MooseX::Types::Email qw(EmailAddress);
use Time::Moment;

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
    default => sub {
        return Time::Moment->now->to_string;
    }
);

has 'reply_to' => (
    is=>'ro',
    isa=>'Str',
);

has 'status' => (
    is=>'ro',
    isa=>'Str', # TODO enum(draft, pending, online, deleted)
    default=>'draft',
);

has 'secret' => (
    is=>'ro',
    isa=>'Str',
    default=>'s3cr3t', # TODO random
);

# TODO format?

has 'user_name' => (
    is=>'ro',
    isa=>'Str',
    required=>1,
);

has 'user_email' => (
    is=>'ro',
    isa=>EmailAddress,
);

has 'user_notify' => (
    is=>'ro',
    isa=>'Str', # TODO enum(none, replies, all)
);

has 'user_email_is_verified' => (
    is=>'ro',
    isa=>'Bool',
    default=>0,
);

has 'user_email_verified_at' => (
    is=>'ro',
    isa=>'Time::Moment'
);

__PACKAGE__->meta->make_immutable;
