use v6;
use Druid::Game::Observer;

#| This role enables objects to be I<observed> by one or more
#| C<Druid::Game::Observer>s, i.e. to notify these when the object changes
#| state in any of various ways. This role only handles the adding of
#| observers; the actual state change notifications are made by classes doing
#| this role.
#|
#| Examples of classes which might want to observe a C<Druid::Game::Subject>
#| are classes derived from C<Druid::View> or C<Druid::Player>.
unit role Druid::Game::Subject;

has Druid::Game::Observer @.observers;

#| Attaches a C<Druid::Game::Observer> to this object. From now on,
#| notifications going out to all listening objects will also go out to the
#| added C<Druid::Game::Observer>.
method attach(Druid::Game::Observer $observer) {
    unless any(@.observers) === $observer {
        @.observers.push($observer);
    }
}

# vim: filetype=perl6
