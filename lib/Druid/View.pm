use v6;

use Druid::Game;
use Druid::Game::Observer;

=begin SUMMARY
Base class for classes that represent a C<Druid::Game> visually.
=end SUMMARY

class Druid::View is Druid::Base does Druid::Game::Observer {
    has Druid::Game $!game handles <size layers colors heights>;
}

# vim: filetype=perl6
