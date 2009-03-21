use v6;

use Druid::Base;
use Druid::Game::Subject;

class Druid::Game is Druid::Base does Druid::Game::Subject {
    has $.size;
    has @.layers;
    has @.heights;
    has @.colors;
    has $.player-to-move;

    has $!last_move;

    method init() {
        die "Forbidden size: $!size"
            unless 3 <= $!size <= 26;

        @!heights = map { [ 0 xx $!size ] }, ^$!size;
        @!colors  = map { [ 0 xx $!size ] }, ^$!size;
        $!player-to-move = 1;
    }

    # Analyzes a given move, and makes the appropriate changes to the given
    # game state data structures. Throws exceptions if the move isn't valid.
    method make-move($move) {

        my @pieces_to_put;

        my $color = $!player-to-move;

        given $move {
            when $.sarsen_move {
                my $row = $<coords><row_number> - 1;
                my $column = ord($<coords><col_letter>) - ord('a');
                my $height = @!heights[$row][$column];

                fail "The highest column is '{chr(ord('A')+$.size-1)}'"
                    if $column >= $.size;
                fail 'There is no row 0'
                    if $row == -1;
                fail "There are only {$.size} rows"
                    if $row >= $.size;

                fail sprintf, q[Not %s's spot],
                              <. vertical horizontal>[$color]
                    unless $.colors[$row][$column] == 0|$color;

                @pieces_to_put = $height, $row, $column;
            }

            when $.lintel_move {
                my $row_1    = $<coords>[0]<row_number> - 1;
                my $row_2    = $<coords>[1]<row_number> - 1;
                my $column_1 = ord($<coords>[0]<col_letter>) - ord('a');
                my $column_2 = ord($<coords>[1]<col_letter>) - ord('a');
                my $height   = @!heights[$row_1][$column_1];
                my $row_m    = ($row_1    + $row_2   ) / 2;
                my $column_m = ($column_1 + $column_2) / 2;

                @pieces_to_put = $height, $row_1, $column_1,
                                 $height, $row_m, $column_m,
                                 $height, $row_2, $column_2;
            }

            when $.pass {
                # Nothing happens
            }

            default { die "Nasty syntax."; }
        }

        for @pieces_to_put -> $height, $row, $column {

            if $height >= @!layers {
                push @!layers, [map { [0 xx $!size] }, ^$!size];
            }
            @!layers[$height][$row][$column]
                = @!colors[$row][$column]
                = $color;
            @!heights[$row][$column] = $height + 1;

            .add_piece($height, $row, $column, $color) for @!observers;
        }

        $!last_move = $move;
        $!player-to-move = 3 - $color; # 1 => 2, 2 => 1

        return;
    }

    # Starting from the last move made, traces the chains to determine whether
    # the two sides have been connected.
    method move_was_winning() {

        my ($row, $column);
        given $!last_move {
            when $.sarsen_move {
                $row    = $<coords><row_number> - 1;
                $column = ord($<coords><col_letter>) - ord('a');
            }
            when $.lintel_move {
                $row    = $<coords>[0]<row_number> - 1;
                $column = ord($<coords>[0]<col_letter>) - ord('a');
            }
            default { return False; } # pass or unknown move type
        }

        my @pos_queue = { :$row, :$column };

        my $last_color = @!colors[$row][$column];

        my &above = { .<row>    < $!size - 1 && { :row(.<row> + 1),
                                                  :column(.<column>) } };
        my &below = { .<row>    > 0          && { :row(.<row> - 1),
                                                  :column(.<column>) } };
        my &right = { .<column> < $!size - 1 && { :row(.<row>),
                                                  :column(.<column> + 1) } };
        my &left  = { .<column> > 0          && { :row(.<row>),
                                                  :column(.<column> - 1) } };

        my %visited;
        my $reached_one_end   = False;
        my $reached_other_end = False;

        while shift @pos_queue -> $pos {
            ++%visited{~$pos};

            for &above, &below, &right, &left -> &direction {
                my ($r, $c) = .<row>, .<column> given $pos;
                if direction($pos) -> $neighbor {

                    if !%visited.exists(~$neighbor)
                       && @!colors[$neighbor<row>][$neighbor<column>]
                          == $last_color {

                        push @pos_queue, $neighbor;
                    }
                }
            }

            if    $last_color == 1 && !above($pos)
               || $last_color == 2 && !right($pos) {

                $reached_one_end   = True;
            }
            elsif    $last_color == 1 && !below($pos)
                  || $last_color == 2 &&  !left($pos) {

                $reached_other_end = True;
            }

            return True if $reached_one_end && $reached_other_end;
        }

        return False;
    }
}

# vim: filetype=perl6
