package Senph::API::Request;
use 5.026;

# ABSTRACT: Request class providing various helper methods

use Moose;

extends 'OX::Request';
with qw(Web::Request::Role::JSON Web::Request::Role::Response);

__PACKAGE__->meta->make_immutable;

