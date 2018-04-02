package Senph::PSGI::Request;
use 5.026;

# ABSTRACT: Request class providing various helper methods

use Moose;

extends 'Web::Request';
with qw(Web::Request::Role::JSON Web::Request::Role::Response);

__PACKAGE__->meta->make_immutable;

