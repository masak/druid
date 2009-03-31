use v6;
use Druid::Game;
use Druid::Game::Observer;

class Druid::Player is Druid::Base does Druid::Game::Observer {
    has Druid::Game $!game handles <size layers colors heights>;
    has Int $.color;

    # RAKUDO: Workaround while 'new' doesn't completely work in Rakudo.
    method init() {
        $!game.attach(self);
        return self;
    }

    method choose_move() { ... }

    method make-move($move) { $!game.make-move($move) }

    method swap() {
        $!color = $!color == 1 ?? 2 !! 1;
    }

    method Str() { return <Vertical Horizontal>[$!color-1] }
}

# vim: filetype=perl6
