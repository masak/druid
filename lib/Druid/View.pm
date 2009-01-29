use v6;
use Druid::Game;
use Druid::Game::Observer;

class Druid::View does Druid::Game::Observer {
    has Druid::Game_ $!game;
}
