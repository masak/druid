use v6;
use Druid::Game;

class Druid::Player {
    has Druid::Game_ $!game handles <size layers colors heights>;
    has Int $.color;

    method choose_move() { ... }

    method make_move($move) { $!game.make_move($move, $!color) }

    method Str() { return <Vertical Horizontal>[$!color-1] }
}
