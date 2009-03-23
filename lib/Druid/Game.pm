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

    method is-sarsen-move-bad(Int $row, Int $column, Int $color) {
        return "The rightmost column is '{chr(ord('A')+$.size-1)}'"
            if $column >= $.size;
        return 'There is no row 0'
            if $row == -1;
        return "There are only {$.size} rows"
            if $row >= $.size;

        return sprintf q[Not %s's spot],
                       <. vertical horizontal>[$color]
            unless $.colors[$row][$column] == 0|$color;

        return; # The move is fine.
    }

    method is-lintel-move-bad(Int $row_1, Int $row_2,
                              Int $column_1, Int $column_2,
                              Int $color) {

        return "The rightmost column is '{chr(ord('A')+{$.size}-1)}'"
            if $column_1|$column_2 >= $.size;
        return 'There is no row 0'
            if $row_1|$row_2 == -1;
        return "There are only {$.size} rows"
            if $row_1|$row_2 >= $.size;

        my $row_diff    = abs($row_1 - $row_2);
        my $column_diff = abs($column_1 - $column_2);

        return 'A lintel must be three units long'
            unless $row_diff == 2 && $column_diff == 0
                || $row_diff == 0 && $column_diff == 2;

        return 'A lintel must be supported at both ends'
            unless $.heights[$row_1][$column_1]
                == $.heights[$row_2][$column_2];

        my $row_m    = ($row_1    + $row_2   ) / 2;
        my $column_m = ($column_1 + $column_2) / 2;

        return 'A lintel must lie flat'
            unless $.heights[$row_m][$column_m]
                <= $.heights[$row_1][$column_1];

        return 'A lintel cannot lie directly on the ground'
            unless $.heights[$row_1][$column_1];

        return 'A lintel must rest on exactly two pieces of its own color'
            unless 2 == elems grep { $_ == $color },
                $.colors[$row_1][$column_1],        # first end...
                $.colors[$row_2][$column_2],        # ...second end...
                $.heights[$row_m][$column_m] == $.heights[$row_1][$column_1]
                    ?? $.colors[$row_m][$column_m]  # ...middle piece only if
                    !! ();                          # it's level with both ends

        return; # The move is fine.
    }

    # Analyzes a given move, and makes the appropriate changes to the given
    # game state data structures. Throws exceptions if the move isn't valid.
    method make-move($move) {

        my @pieces_to_put;

        my $color = $!player-to-move;

        given $move {
            when $.sarsen_move {
                # RAKUDO: Hoping these explicit int(...) conversions won't be
                #         necessary in the long run.
                my Int $row    = int($<coords><row_number> - 1);
                my Int $column = int(ord($<coords><col_letter>) - ord('a'));

                fail $reason if my $reason
                    = self.is-sarsen-move-bad($row, $column, $color);

                my $height     = @!heights[$row][$column];
                @pieces_to_put = $height, $row, $column;
            }

            when $.lintel_move {
                # RAKUDO: Hoping these explicit int(...) conversions won't be
                #         necessary in the long run.
                my Int $row_1    = int($<coords>[0]<row_number> - 1);
                my Int $row_2    = int($<coords>[1]<row_number> - 1);
                my Int $column_1
                    = int(ord($<coords>[0]<col_letter>) - ord('a'));
                my Int $column_2
                    = int(ord($<coords>[1]<col_letter>) - ord('a'));

                fail $reason if my $reason
                    = self.is-lintel-move-bad($row_1, $row_2,
                                              $column_1, $column_2,
                                              $color);

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

            default { fail "Nasty syntax."; }
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
