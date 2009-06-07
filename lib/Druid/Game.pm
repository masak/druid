use v6;

use Druid::Base;
use Druid::Game::Subject;

class Druid::Game is Druid::Base does Druid::Game::Subject;

=begin SUMMARY
An instance of C<Druid::Game> holds an ongoing (or finished) Druid game.
It keeps track of the contents of the board, whose turn it is, the number
of moves made, and whether the game is over. The methods in this class
are created so as to disallow all illegal moves (or other actions) on the
game state. In other words, an invariant of this class is that it is
always in a permitted states, according to the rules of Druid.

The class does the role C<Druid::Game::Subject>, making it possible for
instances of other classes to subscribe to updates from instances of this
class, in an B<observer> pattern.
=end SUMMARY

=attr The size of a side of the (always quadratic) board.
has $.size;
=attr An array of layers, each a C<$.size * $.size> AoA with color info.
has @.layers;
=attr A C<$.size * $.size> AoA with height info.
has @.heights;
=attr A C<$.size * $.size> AoA with color info.
has @.colors;
=attr An integer (either 1 or 2) denoting whose turn it is to move.
has $.player-to-move;
=attr The number of moves made so far in the game, including swapping.
has $.moves-so-far;
=attr Whether the game has already ended.
has $.finished;

has $!latest-move;

# RAKUDO: This could be done with BUILD instead, as soon as BUILD can
#         access private attributes. [perl #64388]
method new(:$size = 3) {
    die "Forbidden size: $size"
        unless 3 <= $size <= 26;

    return self.bless( self.CREATE(),
                       :size($size),
                       :heights(map { [ 0 xx $size ] }, ^$size),
                       :colors( map { [ 0 xx $size ] }, ^$size),
                       :player-to-move(1) );
}

=begin METHOD
Reports C<False> if the move is permissible in the given state of the game,
or a C<Str> explaining why if it isn't. (Thus 'bad' here means
'impermissible', but 'bad' is less to write.)
=end METHOD
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
            return '
The move does not conform to the accepted move syntax, which is either
something like "b2" or something like "c1-c3" You can also "pass" or
"resign" on any move, and "swap" on the second move of the game.'.substr(1);
        }
    }

    return False; # move is OK
}

=begin METHOD
Returns, for given C<$row>, C<$column>, and C<$color>, the reason why
a sarsen (a one-block piece) of that color cannot be placed on that location,
or C<False> if the placing of the sarsen is permissible.
=end METHOD
method is-sarsen-move-bad(Int $row, Int $column, Int $color) {
    return "The rightmost column is '{chr(ord('A')+$.size-1)}'"
        if $column >= $.size;
    return 'There is no row 0'
        if $row == -1;
    return "There are only {$.size} rows"
        if $row >= $.size;

    return sprintf q[Not %s's spot], <. vertical horizontal>[$color]
        unless $.colors[$row][$column] == 0|$color;

    return False; # The move is fine.
}

=begin METHOD
Returns, for a given C<$row_1>, C<$row_2>, C<$column_1>, C<$column_2>, and
C<$color>, the reason why a lintel (a three-block piece) of that color cannot
be placed bridging these locations, or C<False> if the placing of the lintel
is permissible.

There are no preconditions on the coordinate parameters to be exactly two
rows or two columns apart; instead, these conditions are also tested in this
method.
=end METHOD
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
            $.colors[$row_1][$column_1],        # one end...
            $.colors[$row_2][$column_2],        # ...other end...
            $.heights[$row_m][$column_m] == $.heights[$row_1][$column_1]
                ?? $.colors[$row_m][$column_m]  # ...middle piece only if
                !! ();                          # it's level with both ends

    return False; # The move is fine.
}

=begin METHOD
Analyzes a given move, and makes the appropriate changes to the attributes
of this C<Druid::Game>. C<fail>s if the move isn't valid.
=end METHOD
method make-move(Str $move) {

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

=begin METHOD
Returns a C<Bool> indicating whether the latest move created a winning chain
across the board.
=end METHOD
submethod move-was-winning() {

    my ($row, $col) = self.extract-coords(
        $!latest-move ~~ $.sarsen-move ?? $<coords>    !!
        $!latest-move ~~ $.lintel-move ?? $<coords>[0] !!
        return False # swap or pass or other kind of move
    );

    # Starting from the latest move made, traces the chains to determine
    # whether the two sides have been connected. Since the winning chain
    # must by necessity contain the last move, this is equivalent to
    # asking 'was the last move winning?'.

    my @pos-queue = { :$row, :$col };

    my $latest-color = @!colors[$row][$col];

    # The following four code variables take a step in either of the
    # four compass directions. Given a position as a two-entry hash
    # (:row, :col), it returns a neighboring position as a new such
    # hash or C<Bool::False> if the position would be outside of
    # the board.
    my &above
        = { .<row> < $!size - 1 && { :row(.<row> + 1), :col(.<col>) } };
    my &below
        = { .<row> > 0          && { :row(.<row> - 1), :col(.<col>) } };
    my &right
        = { .<col> < $!size - 1 && { :row(.<row>), :col(.<col> + 1) } };
    my &left
        = { .<col> > 0          && { :row(.<row>), :col(.<col> - 1) } };

    my %visited;
    my $reached-one-end   = False;
    my $reached-other-end = False;

    while shift @pos-queue -> $pos {
        ++%visited{~$pos};

        for &above, &below, &right, &left -> &direction {
            my ($r, $c) = .<row>, .<col> given $pos;
            if direction($pos) -> $neighbor {

                if !%visited.exists(~$neighbor)
                   && @!colors[$neighbor<row>][$neighbor<col>]
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

=begin METHOD
Returns a C<List> of the possible moves in this C<Druid::Game>, represented as
C<Str>s.
=end METHOD
method possible-moves() {
    # We don't handle lintel moves yet. :( I have a nice O(1) algorithm,
    # but very little time.
    return gather for ^$!size -> $row {
        for ^$!size -> $column {
            if @!colors[$row][$column] == 0|$!player-to-move {
                take chr($column + ord("a")) ~ ($row+1);
            }
        }
    }
}

# vim: filetype=perl6
