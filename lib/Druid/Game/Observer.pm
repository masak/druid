use v6;

=begin SUMMARY
This role enables objects to I<observe> a C<Druid::Game::Subject>, i.e.
to be notified when that instance changes state in any of various ways.
In concrete terms, an object doing C<Druid::Game::Observer> is added to
a list of observers in a C<Druid::Game::Subject>, which then makes sure
to call the below methods on all observers in that list whenever the
corresponding state change happens in the subject.

Examples of classes which might want to observe a C<Druid::Game::Subject>
are classes derived from C<Druid::View> or C<Druid::Player>.
=end SUMMARY

role Druid::Game::Observer {
=begin METHOD
Gets called any time the C<Druid::Game::Subject> adds a piece to its game
board. Note that, for the purposes of this method, lintels are considered
to be three adjacent (but separate) pieces.
=end METHOD
    method add-piece($height, $row, $column, $color) { ... };

=begin METHOD
Gets called when the C<Druid::Game::Subject> swaps positions between the
two players.
=end METHOD
    method swap() { ... }
}

# vim: filetype=perl6
