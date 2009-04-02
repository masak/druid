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

        given $move {
            when $.sarsen_move {
                my Int $row    = int($<coords><row_number> - 1);
                my Int $column = int(ord($<coords><col_letter>) - ord('a'));

                if $!game.is-sarsen-move-bad($row, $column, $.color)
                  -> $reason {
                    say $reason;
                    return;
                }
            }

            when $.lintel_move {
                my Int $row_1    = int($<coords>[0]<row_number> - 1);
                my Int $row_2    = int($<coords>[1]<row_number> - 1);
                my Int $column_1 = int(ord($<coords>[0]<col_letter>)
                                       - ord('a'));
                my Int $column_2 = int(ord($<coords>[1]<col_letter>)
                                       - ord('a'));

                if $!game.is-lintel-move-bad($row_1, $row_2,
                                             $column_1, $column_2,
                                             $.color) -> $reason {
                    say $reason;
                    return;
                }
            }

            when $.swap {
                if $!game.moves-so-far != 1 {
                    say "Can only swap on the second move of the game.";
                    return;
                }
            }

            when $.pass | $.resign {
                # Always valid -- no error-checking needed.
            }

            default {
                say '
The move does not conform to the accepted move syntax, which is either
something like "b2" or something like "c1-c3" You can also "pass" on
any move, and "swap" on the second move of the game.'.substr(1);
                return;
            }
        }

        return $move;
    }
}

# vim: filetype=perl6
