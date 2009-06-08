use v6;

use Druid::Game;
use Druid::Game::Observer;

class Druid::View is Druid::Base does Druid::Game::Observer;

=begin SUMMARY
Base class for classes that represent a C<Druid::Game> visually.
=end SUMMARY

has Druid::Game $!game handles <size layers colors heights>;

submethod BUILD(Druid::Game :$game!) {
    $game.attach(self);
    # RAKUDO: These attributes should be auto-initialized
    $!game = $game;
}

# vim: filetype=perl6
