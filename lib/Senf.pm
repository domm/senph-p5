package Senf;
use 5.026;

# ABSTRACT: simple comment system / disqus clone

use Moose;
use Bread::Board;

use Module::Runtime 'use_module';
use Config::ZOMG;

use Senf::X;

use Senf::Object::Site;
use Senf::Object::Topic;
use Senf::Object::Comment;

my $config = Config::ZOMG->new( name => "senf", path => "etc" );

my $c = container 'Senf' => as {
    container 'App' => as {
        service 'api.psgi' => (
            class        => 'Senf::API::OX',
            lifecycle    => 'Singleton',
            dependencies => { comment_ctrl => '/API/Comment', }
        );
    };

    container 'API' => as {
        service 'Comment' => (
            lifecycle    => 'Singleton',
            class        => 'Senf::API::Ctrl::Comment',
            dependencies => { comment_model => '/Model/Comment', }
        );
    };

    container 'Model' => as {
        service 'Comment' => (
            lifecycle => 'Singleton',
            class     => 'Senf::Model::Comment',
            dependencies => {
                storage => literal( $config->load->{data_dir} ),
            }
        );
    }

};

sub init {
    return $c;
}

1;

