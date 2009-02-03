use v6;

use Druid::Game::Observer;

role Druid::Game::Subject {
    # RAKUDO: Typed arrays don't really work yet
#    has Druid::Game::Observer @!observers;
    has @!observers;

    method attach(Druid::Game::Observer $observer) {
        unless @!observers ~~ (*, $observer, *) {
            @!observers.push($observer);
        }
    }
}

# vim: filetype=perl6
