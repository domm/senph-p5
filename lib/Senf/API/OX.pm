package Senf::API::OX;
use 5.026;

# ABSTRACT: Just another OX

use OX;
use Plack::Runner;
use Log::Any qw($log);

sub request_class {'Senf::API::Request'}

has 'comment_ctrl' => (
    is       => 'ro',
    isa      => 'Senf::API::Ctrl::Comment',
    required => 1,
);

router as {

    wrap 'Plack::Middleware::PrettyException';

    route '/comment/:ident' => 'comment_ctrl.item';
};

sub run {
    return shift->to_app;
}

__PACKAGE__->meta->make_immutable;

