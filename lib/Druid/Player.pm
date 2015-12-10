use v6;

use Druid::Game;
use Druid::Game::Observer;

#| Represents a generic Druid player. A player belongs to a certain game, has
#| a piece color in that game, and is responsible for choosing legal moves
#| and making them.
unit class Druid::Player is Druid::Base does Druid::Game::Observer;

#| The game this C<Druid::Player> is playing.
has Druid::Game $.game handles <size layers colors heights make-move>;
#| The color of this C<Druid::Player>'s pieces.
has Int $.color where 1|2;

method new(Druid::Game :$game!, Int :$color! where { $_ == 1|2 }) {
    self.bless(:$game, :$color);
}

submethod BUILD(Druid::Game :$game!, Int :$color! where { $_ == 1|2 }) {
    $!game = $game;
    $!color = $color;
    $!game.attach(self);
}

method choose-move() { ... }

method reset() { ... }

method swap() {
    $!color = $!color == 1 ?? 2 !! 1;
}

method Str() { return <Vertical Horizontal>[$.color-1] }

# vim: filetype=perl6
