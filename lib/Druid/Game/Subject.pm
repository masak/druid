use v6;

use Druid::Game::Observer;

role Druid::Game::Subject {
    has Druid::Game::Observer @!observers;

    method attach(Druid::Game::Observer $observer) {
        unless @!observers ~~ *, $observer, * {
            @!observers.push($observer);
        }
    }
}

# vim: filetype=perl6
