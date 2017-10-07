package Senf;
use 5.026;

# ABSTRACT: simple comment system / disqus clone

use Moose;
use Bread::Board;

use Module::Runtime 'use_module';
use Path::Class;
use String::CamelCase qw(decamelize);
use Config::ZOMG;

use Senf::X;

my $config = Config::ZOMG->new( name => "senf", path => "etc" );

my $c = container 'Senf' => as {
    container 'App' => as {
        service 'foo' => (
            class=>'Senf::Foo',
            lifecycle    => 'Singleton',
        );
        #   service 'oe1_web.psgi' => (
        #       class        => 'Oe1::Web::OX',
        #       lifecycle    => 'Singleton',
        #       dependencies => {
        #           static_dir    => '/Path/web_assets',
        #           uimg_dir      => '/Path/upload_image',
        #           renderer      => '/Renderer/html',
        #           session_store => '/Session/Web/store',
        #           session_state => '/Session/Web/state',

        #           map { decamelize($_) . '_model' => '/Model/Web/' . $_ }
        #               qw(Url Article Collection Broadcast BurgerNavigation Account Form Timemachine Ugc Author Search Hoerspiel Poll),
        #       }
        #   );
    };
};

sub init {
    return $c;
}

1;

