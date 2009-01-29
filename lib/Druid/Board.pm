use v6;
use Druid::Game::Observer;

class Druid::Board does Druid::Game::Observer {
    has Druid::Game_ $!game;
}
