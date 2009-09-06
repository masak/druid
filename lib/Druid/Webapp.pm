use v6;

use Web::Request;
use Web::Response;

use Druid::Game; 
use Druid::View::Text;

class Druid::Webapp does Callable {
    method postcircumfix:<( )>($env) {
        my $board-size = 8;
        my Druid::Game $game .= new(:size($board-size));
        my Druid::View $view = Druid::View::Text.new(:$game);

        my Web::Response $res .= new;
        $res.write($_) for
            '<title>Druid</title>',
            '<pre>',
            $view,
            '</pre>';
        $res.finish();
    }
}
