package Senph::PSGI::Ctrl::Approve;
use 5.026;

# ABSTRACT: Web Controller for approv

use Moose;

has 'comment_model' => (
    is       => 'ro',
    isa      => 'Senph::Model::Comment',
    required => 1,
);

__PACKAGE__->meta->make_immutable;

