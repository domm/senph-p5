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

    route '/comments/:site/:topic' => 'comment_ctrl.list'; # GET
    route '/comment/:site/:topic' => 'comment_ctrl.create'; # GET (show form) / POST
    route '/reply/:site/:topic/:reply_to_path/:reply_to_ident' => 'comment_ctrl.reply'; # POST

    route '/hmm/:site/:topic/:comment_path/:comment_ident/:comment_secret/publish' => 'comment_ctrl.publish';
    route '/hmm/:site/:topic/:comment_path/:comment_ident/:comment_secret/edit' => 'comment_ctrl.edit';
    route '/hmm/:site/:topic/:comment_path/:comment_ident/:comment_secret/delete' => 'comment_ctrl.delete';



};

sub run {
    return shift->to_app;
}

__PACKAGE__->meta->make_immutable;

