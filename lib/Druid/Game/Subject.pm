use v6;
use Druid::Game::Observer;

role Druid::Game::Subject;

=begin SUMMARY
This role enables objects to be I<observed> by one or more
C<Druid::Game::Observer>s, i.e. to be notify these when the object changes
state in any of various ways. This role only handles the adding of observers;
the actual state change notifications are made by classes doing this role.

Examples of classes which might want to observe a C<Druid::Game::Subject>
are classes derived from C<Druid::View> or C<Druid::Player>.
=end SUMMARY

# RAKUDO: Typed arrays don't really work yet
#has Druid::Game::Observer @!observers;
has @!observers;

method attach(Druid::Game::Observer $observer) {
    unless @!observers ~~ (*, $observer, *) {
        @!observers.push($observer);
    }
}

# vim: filetype=perl6
