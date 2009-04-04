use v6;
use Druid::Player;

class Druid::Player::Human is Druid::Player {
    method choose_move() {
        repeat {
            print "\n{self}: "
        } until my $move = self.input_valid_move();
        return $move;
    }

    # Reads a string from STDIN, and checks it for validity in various ways.
    # As a first check, the move syntax is checked to be either a sarsen move
    # or a lintel move. A valid sarsen move must be placed on the ground or on
    # stones of the same color. A valid lintel move must cover exactly three
    # locations in a row, and the lintel itself must have stones under both
    # ends, and two of the maximally three supporting stones must be of the
    # placed lintel's color.
    submethod input_valid_move() {

        my $move = =$*IN;
        say '' and exit(1) if $*IN.eof;

        if $!game.is-move-bad($move) -> $reason {
            say $reason;
            return;
        }

        return $move;
    }
}

# vim: filetype=perl6
