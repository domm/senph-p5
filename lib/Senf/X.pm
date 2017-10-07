package Senf::X;
use Moose;
with qw(Throwable::X);

use Throwable::X -all;

has [qw(http_status)] => (
    is      => 'ro',
    default => 400,
    traits  => [Payload],
);

no Moose;
__PACKAGE__->meta->make_immutable;


