use v6;

use Druid::Game;
use Druid::Game::Observer;

class Druid::Player is Druid::Base does Druid::Game::Observer;

=begin SUMMARY
Represents a generic Druid player. A player belongs to a certain game, has
a piece color in that game, and is responsible for choosing legal moves
and making them.
=end SUMMARY

=attr The game this C<Druid::Player> is playing.
has Druid::Game $!game handles <size layers colors heights make-move>;
=attr The color of this C<Druid::Player>'s pieces.
has Int $.color where { $_ == 1|2 };

# RAKUDO: This could be done with BUILD instead, as soon as BUILD can
#         access private attributes. [perl #64388]
method new(Druid::Game :$game!, Int :$color! where { $_ == 1|2 }) {
    my $player = self.bless( self.CREATE(), :game($game), :color($color) );
    $game.attach($player);
    return $player;
}

method choose-move() { ... }

method swap() {
    $!color = $!color == 1 ?? 2 !! 1;
}

method Str() { return <Vertical Horizontal>[$!color-1] }

# vim: filetype=perl6
