package Senph;
use 5.026;

# ABSTRACT: simple comment system / disqus clone

our $VERSION = '0.001';

use Moose;
use Bread::Board;

use Module::Runtime 'use_module';
use Config::ZOMG;

use Senph::X;

use Senph::Object::Site;
use Senph::Object::Topic;
use Senph::Object::Comment;

my $config = Config::ZOMG->new( name => "senph", path => "etc" );

my $c = container 'Senph' => as {
    container 'App' => as {
        service 'senph.pl' => (
            class        => 'Senph::API::AsyncPSGI',
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
            class        => 'Senph::API::Ctrl::Comment',
            dependencies => { comment_model => '/Model/Comment' }
        );
    };

    container 'Model' => as {
        service 'Comment' => (
            lifecycle    => 'Singleton',
            class        => 'Senph::Model::Comment',
            dependencies => { store => '/Store/File', }
        );
    };

    container 'Store' => as {
        service 'File' => (
            lifecycle    => 'Singleton',
            class        => 'Senph::Store',
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

