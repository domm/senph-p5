package Senph::Object::Comment;
use 5.026;

# ABSTRACT: a comment

use Moose;
use MooseX::Storage;

use MooseX::Types::Email qw(EmailAddress);
use Moose::Util::TypeConstraints;
use Time::Moment;
use Digest::SHA1 qw(sha1_base64);
use Time::HiRes qw(time);

with Storage( 'format' => 'JSON', 'io' => 'AtomicFile' );

enum 'SenphCommentStatus' => [qw(pending rejected online)];

enum 'SenphCommentUserNotify' => [qw(none replies all)];

has 'ident' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'body' => (
    is       => 'ro',
    isa      => 'Str',
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

has 'created' => (
    is      => 'ro',
    isa     => 'Str',    # TODO validate iso8601
    default => sub {
        return Time::Moment->now->to_string;
    }
);

has 'status' => (
    is      => 'ro',
    isa     => 'SenphCommentStatus',
    default => 'pending',
);

has 'is_deleted' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has 'secret' => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
);

sub _build_secret {
    my $self = shift;
    my $digest = sha1_base64( time, rand(10000), $$, $^T );
    $digest =~ tr{/+}{_-}; # poor person's base64url
    return $digest;
}

# TODO format?

has 'user_name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'user_email' => (
    is  => 'ro',
    isa => EmailAddress,
);

has 'user_notify' => (
    is  => 'ro',
    isa => 'Maybe[SenphCommentUserNotify]',
);

has 'user_email_is_verified' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has 'user_email_verified_at' => (
    is  => 'ro',
    isa => 'Str',    # TODO validate iso8601
);

has 'user_email_verified_ip' => (
    is  => 'ro',
    isa => 'Str',
);

has 'memo' => (
    is=>'ro',
    isa=>'Str',
);

__PACKAGE__->meta->make_immutable;
