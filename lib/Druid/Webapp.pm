use v6;

use Web::Request;
use Web::Response;

use Druid::Game; 
use Druid::View::Text;

class Druid::Webapp does Callable {
    method postcircumfix:<( )>($env) {
        my Web::Request $req .= new($env);

        my $GAME_STATE_FILE = 'board.data';

        my $board-size = 8;
        my Druid::Game $game .= new(:size($board-size));
        my Druid::View $view = Druid::View::Text.new(:$game);
        if $GAME_STATE_FILE ~~ :e {
            $game.melt(slurp($GAME_STATE_FILE));
        }

        if $req.GET.<move> -> $move {
            $game.make-move($move);
        }
        if open($GAME_STATE_FILE, :w) -> $fh {
            $fh.print($game.gelatinize());
            $fh.close();
        }

        my Web::Response $res .= new;
        $res.write($_) for
            '<title>Druid</title>',
            '<pre>',
            $view,
            '</pre>',
            '<p>';
        $res.write("<a href='?move=$_'>$_</a> ") for $game.possible-moves();
        $res.write('</p>');
        $res.finish();
    }
}
