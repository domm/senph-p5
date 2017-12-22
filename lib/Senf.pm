package Senf;
use 5.026;

# ABSTRACT: simple comment system / disqus clone

our $VERSION = '0.001';

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
        service 'senf.pl' => (
            class        => 'Senf::API::AsyncPSGI',
            lifecycle    => 'Singleton',
            dependencies => {
                comment_ctrl => '/Controller/Comment',
                loop         => '/Async/Loop'
            }
        );
        service 'disqus2senph.pl' => (
            class        => 'Senph::Script::Disqus2Senph',
            lifecycle    => 'Singleton',
            dependencies => {
                comment_model => '/Model/Comment'
            }
        );
    };

    container 'Controller' => as {
        service 'Comment' => (
            lifecycle    => 'Singleton',
            class        => 'Senf::API::Ctrl::Comment',
            dependencies => { comment_model => '/Model/Comment' }
        );
    };

    container 'Model' => as {
        service 'Comment' => (
            lifecycle    => 'Singleton',
            class        => 'Senf::Model::Comment',
            dependencies => { store => '/Store/File', }
        );
    };

    container 'Store' => as {
        service 'File' => (
            lifecycle    => 'Singleton',
            class        => 'Senf::Store',
            dependencies => {
                basedir     => literal( $config->load->{data_dir} ),
                loop        => '/Async/Loop',
                http_client => '/Async/HTTPClient',
            }
        );
    };

    container 'Async' => as {
        service 'Loop' => (
            lifecycle => 'Singleton',
            class     => 'IO::Async::Loop',
        );
        service 'HTTPClient' => (
            lifecycle    => 'Singleton',
            class        => 'Net::Async::HTTP',
            dependencies => { loop => 'Loop', },
            block        => sub {
                my $s    = shift;
                my $loop = $s->param('loop');
                my $http = Net::Async::HTTP->new(
                    user_agent => __PACKAGE__ . '/' . $VERSION,
                    timeout    => 2,
                );
                $loop->add($http);
                return $http;
            },
        );
    };

};

sub init {
    return $c;
}

1;

