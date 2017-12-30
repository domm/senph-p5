package Senph::X;
use Moose;
with qw(Throwable::X);

use Throwable::X -all;

has [qw(http_status)] => (
    is      => 'ro',
    default => 400,
    traits  => [Payload],
);

has [qw(site topic)] => (
    is     => 'ro',
    traits => [Payload],
);

no Moose;
__PACKAGE__->meta->make_immutable;

package Senph::X::Forbidden;
use Moose;
extends 'Senph::X';
use Throwable::X -all;

has '+http_status' => ( default => 403 );

no Moose;
__PACKAGE__->meta->make_immutable;

package Senph::X::NotFound;
use Moose;
extends 'Senph::X';
use Throwable::X -all;

has '+http_status' => ( default => 404 );

no Moose;
__PACKAGE__->meta->make_immutable;

