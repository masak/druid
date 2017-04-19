use v6;

use Druid::Base;
use Druid::Game::Subject;

#| An instance of C<Druid::Game> holds an ongoing (or finished) Druid game.
#| It keeps track of the contents of the board, whose turn it is, the number
#| of moves made, and whether the game is over. The methods in this class
#| are created so as to disallow all illegal moves (or other actions) on the
#| game state. In other words, an invariant of this class is that it is
#| always in a permitted state, according to the rules of Druid.
#|
#| The class does the role C<Druid::Game::Subject>, making it possible for
#| instances of other classes to subscribe to updates from instances of this
#| class, in an B<observer> pattern.
unit class Druid::Game is Druid::Base does Druid::Game::Subject;

#| The size of a side of the (always quadratic) board.
has $.size;
#| An array of layers, each a C<$.size * $.size> AoA with color info.
has @.layers;
#| A C<$.size * $.size> AoA with height info.
has @.heights;
#| A C<$.size * $.size> AoA with color info.
has @.colors;
#| An integer (either 1 or 2) denoting whose turn it is to move.
has $.player-to-move;
#| The number of moves made so far in the game, including swapping.
has $.moves-so-far;
#| Has the game been won or a player resigned?
has $.finished;

has $!latest-move;

submethod BUILD(:$size = 3) {
    die "Forbidden size: $size"
        unless 3 <= $size <= 26;

    @!heights = map { [ 0 xx $size ] }, ^$size;
    @!colors  = map { [ 0 xx $size ] }, ^$size;
    $!player-to-move = 1;
    $!moves-so-far = 0;
    # RAKUDO: These attributes should be auto-initialized
    $!size = $size;
}

#| Turns the state of this C<Druid::Game> into a string which can then be
#| stored, later to be recreated into an object again with the C<.melt> method.
multi method gelatinize() {
    use MONKEY-SEE-NO-EVAL;
    return join '; ', map { $^attr ~ ' = '
                            ~ EVAL($^attr).perl.subst(/^ '[' (.*) ']' $/,
                                                      {"($0)"}) },
                      <$!size @!layers @!heights @!colors $!player-to-move
                       $!moves-so-far $!finished $!latest-move>;
}

multi method melt(Str $ice) {
    use MONKEY-SEE-NO-EVAL;
    # XXX: There are all sorts of security hazards involved in just EVAL-ing
    #      an unknown string like this. Discussing it on #perl6, we concluded
    #      that a solution using YAML or equivalent technology would be a much
    #      better fit. But this works for now.
    EVAL($ice);
    .reset() for @.observers;
}

#| Reports C<False> if the move is permissible in the given state of
#| the game, or a C<Str> explaining why if it isn't. (Thus 'bad' here means
#| 'impermissible', but 'bad' is less to write.)
method is-move-bad(Str $move) {
    my $color = $!player-to-move;

    if Druid::Move.parse($move, :rule<sarsen-move>) {
        my Int ($row, $column) = self.extract-coords($<coords>);

        return my $reason if $reason
            = self.is-sarsen-move-bad($row, $column, $color);
    }
    elsif Druid::Move.parse($move, :rule<lintel-move>) {
        my Int ($row_1, $column_1) = self.extract-coords($<coords>[0]);
        my Int ($row_2, $column_2) = self.extract-coords($<coords>[1]);

        return my $reason if $reason
            = self.is-lintel-move-bad($row_1, $row_2,
                                      $column_1, $column_2,
                                      $color);
    }
    elsif Druid::Move.parse($move, :rule<swap>) {
        return 'Swap is only allowed on second move'
            if $!moves-so-far != 1;
    }
    elsif Druid::Move.parse($move, :rule<pass>)
         || Druid::Move.parse($move, :rule<resign>) {
        # those are always OK
    }
    else {
        return '
The move does not conform to the accepted move syntax, which is either
something like "b2" or something like "c1-c3" You can also "pass" or
"resign" on any move, and "swap" on the second move of the game.'.trim-leading;
    }

    return False; # move is OK
}

#| Returns, for given C<$row>, C<$column>, and C<$color>, the reason why
#| a sarsen (a one-block piece) of that color cannot be placed on that
#| location, or C<False> if the placing of the sarsen is permissible.
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

#| Returns, for a given C<$row_1>, C<$row_2>, C<$column_1>, C<$column_2>, and
#| C<$color>, the reason why a lintel (a three-block piece) of that color
#| can not be placed bridging these locations, or C<False> if the placing of
#| the lintel is permissible.
#|
#| There are no preconditions on the coordinate parameters to be exactly two
#| rows or two columns apart; instead, these conditions are also tested in this
#| method.
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

    my $row_m    = ($row_1    + $row_2   ) div 2;
    my $column_m = ($column_1 + $column_2) div 2;

    return 'A lintel must lie flat'
        unless $.heights[$row_m][$column_m]
            <= $.heights[$row_1][$column_1];

    return 'A lintel cannot lie directly on the ground'
        unless $.heights[$row_1][$column_1];

    return 'A lintel must rest on exactly two pieces of its own color'
        unless 2 == (grep { $_ == $color },
            $.colors[$row_1][$column_1],        # one end...
            $.colors[$row_2][$column_2],        # ...other end...
            $.heights[$row_m][$column_m] == $.heights[$row_1][$column_1]
                ?? $.colors[$row_m][$column_m]  # ...middle piece only if
                !! ()).elems;                   # it's level with both ends

    return False; # The move is fine.
}

#| Analyzes a given move, and makes the appropriate changes to the attributes
#| of this C<Druid::Game>. C<fail>s if the move isn't valid.
method make-move(Str $move) {

    fail my $reason
        if $reason = self.is-move-bad($move);

    my @pieces-to-put;
    my $color = $!player-to-move;

    if Druid::Move.parse($move, :rule<sarsen-move>) {
        my Int ($row, $column) = self.extract-coords($<coords>);

        my $height     = @!heights[$row][$column];
        @pieces-to-put = $height, $row, $column;
    }
    elsif Druid::Move.parse($move, :rule<lintel-move>) {
        my Int ($row_1, $column_1) = self.extract-coords($<coords>[0]);
        my Int ($row_2, $column_2) = self.extract-coords($<coords>[1]);

        my $height   = @!heights[$row_1][$column_1];
        my $row_m    = ($row_1    + $row_2   ) div 2;
        my $column_m = ($column_1 + $column_2) div 2;

        @pieces-to-put = $height, $row_1, $column_1,
                         $height, $row_m, $column_m,
                         $height, $row_2, $column_2;
    }
    elsif Druid::Move.parse($move, :rule<pass>) {
        if $!latest-move.defined &&
                Druid::Move.parse($!latest-move, :rule<pass>) {
            $!finished = True;
        }
    }
    elsif Druid::Move.parse($move, :rule<swap>) {
        .swap() for @.observers;
    }
    elsif Druid::Move.parse($move, :rule<resign>) {
        $!finished = True;
    }

    for @pieces-to-put -> $height, $row, $column {

        if $height >= @!layers {
            push @!layers, [map { [0 xx $!size] }, ^$!size];
        }
        @!layers[$height][$row][$column]
            = @!colors[$row][$column]
            = $color;
        @!heights[$row][$column] = $height + 1;

        .add-piece($height, $row, $column, $color) for @.observers;
    }

    $!latest-move = $move;
    $!player-to-move = $color == 1 ?? 2 !! 1
        unless Druid::Move.parse($move, :rule<swap>);
    $!moves-so-far++;

    if self.move-was-winning() {
        $!finished = True;
    }

    return $move;
}

#| Returns a C<Bool> indicating whether the latest move created
#| a winning chain across the board.
submethod move-was-winning() {

    my ($row, $col) = self.extract-coords(
        Druid::Move.parse($!latest-move, :rule<sarsen-move>) ?? $<coords>    !!
        Druid::Move.parse($!latest-move, :rule<lintel-move>) ?? $<coords>[0] !!
        return False # swap or pass or other kind of move
    );

    # Starting from the latest move made, traces the chains to determine
    # whether the two sides have been connected. Since the winning chain
    # must by necessity contain the last move, this is equivalent to
    # asking 'was the last move winning?'.

    my @pos-queue = { :$row, :$col },;

    my $latest-color = @!colors[$row][$col];

    # The following four code variables take a step in either of the
    # four compass directions. Given a position as a two-entry hash
    # (:row, :col), it returns a neighboring position as a new such
    # hash or C<Bool::False> if the position would be outside of
    # the board.
    my &above
        = { .<row> < $!size - 1 && %( :row(.<row> + 1), :col(.<col>) ) };
    my &below
        = { .<row> > 0          && %( :row(.<row> - 1), :col(.<col>) ) };
    my &right
        = { .<col> < $!size - 1 && %( :row(.<row>), :col(.<col> + 1) ) };
    my &left
        = { .<col> > 0          && %( :row(.<row>), :col(.<col> - 1) ) };

    my %visited;
    my $reached-one-end   = False;
    my $reached-other-end = False;

    while shift @pos-queue -> $pos {
        ++%visited{~$pos};

        for &above, &below, &right, &left -> &direction {
            my ($r, $c) = .<row>, .<col> given $pos;
            if direction($pos) -> $neighbor {

                if %visited{~$neighbor} :!exists
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

#| Returns a C<List> of the possible moves in this C<Druid::Game>,
#| represented as C<Str>s.
method possible-moves() {
    if $!finished {
        return ();
    }
    else {
        return gather {
            for ^$!size X ^$!size -> $row, $column {
                if @!colors[$row][$column] == 0|$!player-to-move {
                    take chr($column + ord("a")) ~ ($row+1);
                }
            }
            for ^($!size - 2) X ^$!size -> $row, $column {
                if @!colors[$row][$column] == @!colors[$row+2][$column]
                   == $!player-to-move && @!heights[$row][$column]
                   == @!heights[$row+2][$column] && @!heights[$row+1][$column]
                   < @!heights[$row][$column] {
                    take chr($column + ord("a")) ~ ($row+1) ~ '-'
                         ~ chr($column + ord("a")) ~ ($row+3);
                }
            }
            for ^$!size X ^($!size - 2) -> $row, $column {
                if @!colors[$row][$column] == @!colors[$row][$column+2]
                   == $!player-to-move && @!heights[$row][$column]
                   == @!heights[$row][$column+2] && @!heights[$row][$column+1]
                   < @!heights[$row][$column] {
                    take chr($column + ord("a")) ~ ($row+1) ~ '-'
                         ~ chr($column + 2 + ord("a")) ~ ($row+1);
                }
            }
            for ^($!size - 2) X ^$!size -> $row, $column {
                if @!heights[$row][$column] == @!heights[$row+1][$column]
                   == @!heights[$row+2][$column] && @!colors[$row][$column]
                   + @!colors[$row+1][$column] + @!colors[$row+2][$column]
                   == 3 + $!player-to-move {
                    take chr($column + ord("a")) ~ ($row+1) ~ '-'
                         ~ chr($column + ord("a")) ~ ($row+3);
                }
            }
            for ^$!size X ^($!size - 2) -> $row, $column {
                if @!heights[$row][$column] == @!heights[$row][$column+1]
                   == @!heights[$row][$column+2] && @!colors[$row][$column]
                   + @!colors[$row][$column+1] + @!colors[$row][$column+2]
                   == 3 + $!player-to-move {
                    take chr($column + ord("a")) ~ ($row+1) ~ '-'
                         ~ chr($column + 2 + ord("a")) ~ ($row+1);
                }
            }
            if $!moves-so-far == 1 {
                take 'swap';
            }
            take <pass resign>;
        }
    }
}

# vim: filetype=perl6
