use v6;

use Druid::Base;
use Druid::Game::Subject;

class Druid::Game is Druid::Base does Druid::Game::Subject {
    has $.size;
    has @.layers;
    has @.heights;
    has @.colors;
    has $.player-to-move;
    has $.moves-so-far;
    has $.finished;

    has $!latest-move;

    # RAKUDO: This could be done with BUILD instead, as soon as BUILD can
    #         access private attributes. [perl #64388]
    method new(:$size = 3) {
        die "Forbidden size: $size"
            unless 3 <= $size <= 26;

        return self.bless( :size($size),
                           :heights(map { [ 0 xx $size ] }, ^$size),
                           :colors( map { [ 0 xx $size ] }, ^$size),
                           :player-to-move(1) );
    }

    method is-move-bad(Str $move) {
        my $color = $!player-to-move;

        given $move {
            when $.sarsen-move {
                my Int ($row, $column) = self.extract-coords($<coords>);

                return $reason if my $reason
                    = self.is-sarsen-move-bad($row, $column, $color);
            }

            when $.lintel-move {
                my Int ($row_1, $column_1) = self.extract-coords($<coords>[0]);
                my Int ($row_2, $column_2) = self.extract-coords($<coords>[1]);

                return $reason if my $reason
                    = self.is-lintel-move-bad($row_1, $row_2,
                                              $column_1, $column_2,
                                              $color);
            }

            when $.swap {
                return 'Swap is only allowed on second move'
                    if $!moves-so-far != 1;
            }

            when $.pass | $.resign {
                # those are always OK
            }

            default {
                fail '
The move does not conform to the accepted move syntax, which is either
something like "b2" or something like "c1-c3" You can also "pass" or
"resign" on any move, and "swap" on the second move of the game.'.substr(1);
            }
        }

        return False; # move is OK
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

        my $row-diff    = abs($row_1 - $row_2);
        my $column-diff = abs($column_1 - $column_2);

        return 'A lintel must be three units long'
            unless $row-diff == 2 && $column-diff == 0
                || $row-diff == 0 && $column-diff == 2;

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

        fail $reason
            if my $reason = self.is-move-bad($move);

        my @pieces-to-put;
        my $color = $!player-to-move;

        given $move {
            when $.sarsen-move {
                my Int ($row, $column) = self.extract-coords($<coords>);

                my $height     = @!heights[$row][$column];
                @pieces-to-put = $height, $row, $column;
            }

            when $.lintel-move {
                my Int ($row_1, $column_1) = self.extract-coords($<coords>[0]);
                my Int ($row_2, $column_2) = self.extract-coords($<coords>[1]);

                my $height   = @!heights[$row_1][$column_1];
                my $row_m    = ($row_1    + $row_2   ) / 2;
                my $column_m = ($column_1 + $column_2) / 2;

                @pieces-to-put = $height, $row_1, $column_1,
                                 $height, $row_m, $column_m,
                                 $height, $row_2, $column_2;
            }

            when $.pass {
                if $!latest-move ~~ $.pass {
                    $!finished = True;
                }
            }

            when $.swap {
                .swap() for @!observers;
            }

            when $.resign {
                $!finished = True;
            }

            default { fail "Nasty syntax."; }
        }

        for @pieces-to-put -> $height, $row, $column {

            if $height >= @!layers {
                push @!layers, [map { [0 xx $!size] }, ^$!size];
            }
            @!layers[$height][$row][$column]
                = @!colors[$row][$column]
                = $color;
            @!heights[$row][$column] = $height + 1;

            .add-piece($height, $row, $column, $color) for @!observers;
        }

        $!latest-move = $move;
        $!player-to-move = $color == 1 ?? 2 !! 1
            unless $move ~~ $.swap;
        $!moves-so-far++;

        if self.move-was-winning() {
            $!finished = True;
        }

        return $move;
    }

    # Starting from the latest move made, traces the chains to determine
    # whether the two sides have been connected.
    submethod move-was-winning() {

        my ($row, $column) = self.extract-coords(
            $!latest-move ~~ $.sarsen-move ?? $<coords>    !!
            $!latest-move ~~ $.lintel-move ?? $<coords>[0] !!
            return False # swap or pass or other kind of move
        );

        my @pos-queue = { :$row, :$column };

        my $latest-color = @!colors[$row][$column];

        my &above = { .<row>    < $!size - 1 && { :row(.<row> + 1),
                                                  :column(.<column>) } };
        my &below = { .<row>    > 0          && { :row(.<row> - 1),
                                                  :column(.<column>) } };
        my &right = { .<column> < $!size - 1 && { :row(.<row>),
                                                  :column(.<column> + 1) } };
        my &left  = { .<column> > 0          && { :row(.<row>),
                                                  :column(.<column> - 1) } };

        my %visited;
        my $reached-one-end   = False;
        my $reached-other-end = False;

        while shift @pos-queue -> $pos {
            ++%visited{~$pos};

            for &above, &below, &right, &left -> &direction {
                my ($r, $c) = .<row>, .<column> given $pos;
                if direction($pos) -> $neighbor {

                    if !%visited.exists(~$neighbor)
                       && @!colors[$neighbor<row>][$neighbor<column>]
                          == $latest-color {

                        push @pos-queue, $neighbor;
                    }
                }
            }

            if    $latest-color == 1 && !above($pos)
               || $latest-color == 2 && !right($pos) {

                $reached-one-end   = True;
            }
            elsif    $latest-color == 1 && !below($pos)
                  || $latest-color == 2 &&  !left($pos) {

                $reached-other-end = True;
            }

            return True if $reached-one-end && $reached-other-end;
        }

        return False;
    }
}

# vim: filetype=perl6
