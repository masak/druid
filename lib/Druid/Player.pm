use v6;
use Druid::Game;

class Druid::Player is Druid::Base {
    has Druid::Game $!game handles <size layers colors heights>;
    has Int $.color;

    method choose_move() { ... }

    method make-move($move) { $!game.make-move($move) }

    method Str() { return <Vertical Horizontal>[$!color-1] }
}

# vim: filetype=perl6
