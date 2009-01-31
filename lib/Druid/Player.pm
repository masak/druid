use v6;

class Druid::Player {
    has Druid::Game::Subject $!game;
    has Int $.color;

    method choose_move() { ... }

    method make_move($move) { $!game.make_move($move, $!color) }

    method Str() { return <Vertical Horizontal>[$!color-1] }
}
