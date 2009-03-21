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

        my &flunk_move = { say $^reason; return };

        my $move = =$*IN;
        say '' and exit(1) if $*IN.eof;

        given $move {
            when $.sarsen_move {
                my Int $row    = int($<coords><row_number> - 1);
                my Int $column = int(ord($<coords><col_letter>) - ord('a'));

                if $.game.is-sarsen-move-bad($row, $column, $.color)
                  -> $reason {
                    flunk_move $reason;
                }
            }

            when $.lintel_move {
                my $row_1    = $<coords>[0]<row_number> - 1;
                my $row_2    = $<coords>[1]<row_number> - 1;
                my $column_1 = ord($<coords>[0]<col_letter>) - ord('a');
                my $column_2 = ord($<coords>[1]<col_letter>) - ord('a');

                flunk_move "The highest column is '{chr(ord('A')+{$.size}-1)}'"
                    if $column_1|$column_2 >= $.size;
                flunk_move 'There is no row 0'
                    if $row_1|$row_2 == -1;
                flunk_move "There are only {$.size} rows"
                    if $row_1|$row_2 >= $.size;

                my $row_diff    = abs($row_1 - $row_2);
                my $column_diff = abs($column_1 - $column_2);

                flunk_move 'Must be exactly two cells apart'
                    unless $row_diff == 2 && $column_diff == 0
                        || $row_diff == 0 && $column_diff == 2;

                flunk_move 'Must be supported at both ends'
                    unless $.heights[$row_1][$column_1]
                        == $.heights[$row_2][$column_2];

                my $row_m    = ($row_1    + $row_2   ) / 2;
                my $column_m = ($column_1 + $column_2) / 2;

                flunk_move 'There is a piece in the way in the middle'
                    unless $.heights[$row_m][$column_m]
                        <= $.heights[$row_1][$column_1];

                flunk_move 'No lintels on the ground'
                    unless $.heights[$row_1][$column_1];

                # Could rely on the numification of Bool here, but that while
                # terser, it would also be harder to understand.
                my $number_of_samecolor_supporting_pieces
                    = ($.colors[$row_1][$column_1] == $!color ?? 1 !! 0)
                    + ($.colors[$row_2][$column_2] == $!color ?? 1 !! 0);

                if    $.heights[$row_m][$column_m]
                   == $.heights[$row_1][$column_1]
                   && $.colors[$row_m][$column_m] == $!color {

                    $number_of_samecolor_supporting_pieces++
                }

                flunk_move 'Must be exactly two of your pieces under a lintel'
                    if $number_of_samecolor_supporting_pieces != 2;
            }

            when $.pass {
                # Nothing to do; it's a pass
            }

            default {
                flunk_move '
The move does not conform to the accepted move syntax, which is either
something like "b2" or something like "c1-c3".'.substr(1);
            }
        }

        return $move;
    }
}

# vim: filetype=perl6
