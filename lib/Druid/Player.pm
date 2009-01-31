use v6;
use Druid::Game;

class Druid::Player is Druid::Base {
    has Druid::Game_ $!game handles <size layers colors heights>;
    has Int $.color;

    method choose_move() { ... }

    method make_move($move) { $!game.make_move($move, $!color) }

    method Str() { return <Vertical Horizontal>[$!color-1] }
}

# vim: filetype=perl6
