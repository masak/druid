use v6;
use Druid::Game::Subject;
use Druid::Game::Observer;

class Druid::View does Druid::Game::Observer {
    has Druid::Game::Subject $!game handles <size layers colors heights>;
}
