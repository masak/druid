use v6;

use Druid::Player;

#| A computer player. It currently tries to move close to its opponent's
#| last move or, failing that, entirely randomly. Thus it is almost
#| ridiculously easily defeatable.
unit class Druid::Player::Computer is Druid::Player;

has $!last-move;

method choose-move() {
    # First, see if we can put a piece close to the previous piece. With
    # luck, this might even block the opponent.
    if $!last-move {
        given $.color {
            when 1 {
                my ($last-row, $last-column) = @($!last-move);
                for ($last-column-2, $last-column-1,
                     $last-column+1, $last-column+2) -> $column {

                    next unless 0 <= $column < $.size;
                    next unless $.colors[$last-row][$column] == 0 | $.color;
                    my $move = chr(ord('a')+$column) ~ ($last-row+1);
                    say '';
                    say "The computer moves $move";
                    return $move;
                }
            }
            when 2 {
                my ($last-row, $last-column) = @($!last-move);
                for ($last-row-2, $last-row-1,
                     $last-row+1, $last-row+2) -> $row {

                    next unless 0 <= $row < $.size;
                    next unless $.colors[$row][$last-column] == 0 | $.color;
                    my $move = chr(ord('a')+$last-column) ~ ($row+1);
                    say '';
                    say "The computer moves $move";
                    return $move;
                }
            }
        }
    }

    # At this point, we content ourself with finding a random spot to
    # settle down on.
    my ($row, $column);
    repeat {
        $row    = (^$.size).pick;
        $column = (^$.size).pick;
    } until $.colors[$row][$column] == 0 | $.color;

    my $move = chr(ord('a')+$column) ~ ($row+1);

    say '';
    say "The computer moves $move";
    return $move;
}

method add-piece($height, $row, $column, $color) {
    $!last-move = [$row, $column];
}

# vim: filetype=perl6
