use v6;

use Druid::Game;
use Druid::Game::Observer;

#= Base class for classes that represent a C<Druid::Game> visually.
unit class Druid::View is Druid::Base does Druid::Game::Observer;

has Druid::Game $.game handles <size layers colors heights>;

method reset() { ... }
method swap() { ... }

submethod BUILD() {
    $!game.attach(self);
}

# vim: filetype=perl6
