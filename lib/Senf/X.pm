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

package Senf::X::Forbidden;
use Moose;
extends 'Senf::X';
use Throwable::X -all;

has '+http_status' => ( default => 403 );

no Moose;
__PACKAGE__->meta->make_immutable;

