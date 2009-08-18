use v6;

use Druid::Game;
use Druid::Game::Observer;

#=[Base class for classes that represent a C<Druid::Game> visually.]
class Druid::View is Druid::Base does Druid::Game::Observer;

has Druid::Game $!game handles <size layers colors heights>;

submethod BUILD(Druid::Game :$game!) {
    $game.attach(self);
    # RAKUDO: This attribute should be auto-initialized
    $!game = $game;
}

# vim: filetype=perl6
