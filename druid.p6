#!perl6

# Given a string (assumed to contain no newlines), replaces a section of that
# string, starting from $column, with the contents of $new_section. When
# replacing characters, two excpetions are made: (1) spaces in $new_section
# are treated as 'transparent', so that they don't replace the old character,
# (2) octothorpes '#' insert actual spaces, i.e. act as a sort of escape
# character for spaces.
sub merge($old_line, $new_section, $column) {
    my $old_line_filled
      = $old_line ~ ' ' x ($column + $new_section.chars - $old_line.chars);
    my $old_section = $old_line_filled.substr($column, $new_section.chars);
    my $merged_section;
    for $old_section.split('').kv -> $char_no, $old_char {
        my $new_char = $new_section.substr($char_no, 1);
        $merged_section ~= $new_char eq ' ' ?? $old_char
                           !! $new_char eq '#' ?? ' ' !! $new_char;
    }

    return $old_line_filled.substr(0, $column)
           ~ $merged_section
           ~ $old_line_filled.substr($column + $new_section.chars);
}

# Given a string representing a piece and one representing the board, returns
# a new board with the piece inserted into some coordinates. This sub assumes
# that pieces are drawn in an order that makes sense, so that pieces in front
# cover those behind.
sub put($piece, $board, $coords) {
    my @lines = $board.split("\n");

    my $layer = substr( $coords, 3 );

    my $line = substr( $coords, 1, 1 );
    my $coord_line = +@lines - 8 - 3 * ($line - 1) - $layer;

    return put($piece, "\n" ~ $board, $coords) if $coord_line < 0;

    my $column = ord( substr($coords, 0, 1).lc ) - ord('a');
    my $coord_column = 3 + 6 * $column + $layer;

    for $piece.split("\n").kv -> $line_no, $piece_line {
        my $board_line = @lines[$coord_line + $line_no];
        @lines[ $coord_line + $line_no ]
            = merge($board_line, $piece_line, $coord_column);
    }

    return @lines.join("\n");
}

# Prints two smaller boards representing (1) who owns each location, and
# (2) how many stones have been piled on each location.
sub print_colors_and_heights(@colors, @heights) {
    my &from_pretty    = { $^pretty.trans( ['#','.'] => ['%d','%s'] ) };
    my &format_colors  = { <. v h>[$^color] };
    my &format_heights = { $^height || '.' };

    my $footer = "\n      A B C D E F G H             A B C D E F G H\n";
    my $header = "$footer\n";

    print $header;
    # RAKUDO: (1..8).reverse stopped working [perl #61644]
    for (1..8).list.reverse -> $row {
        say sprintf from_pretty(
            '   #  . . . . . . . .  #       #  . . . . . . . .  #'
            ),
            $row, (map &format_colors,  @colors[$row-1].values),  $row,
            $row, (map &format_heights, @heights[$row-1].values), $row;
    }
    print $footer;
}

# Reads a string from STDIN, and checks it for validity in various ways.
# As a first check, the move syntax is checked to be either a sarsen move
# or a lintel move. A valid sarsen move must be placed on the ground or on
# stones of the same color. A valid lintel move must cover exactly three
# locations in a row, and the lintel itself must have stones under both
# ends, and two of the maximally three supporting stones must be of the
# placed lintel's color.
sub input_valid_move(@heights, @colors, $color) {

    my &flunk_move = { say $^reason; return };

    my $move = =$*IN;
    exit(1) if $*IN.eof;

    given $move {
        when $sarsen_move {
            my $row = $move.substr(1, 1) - 1;
            my $column = ord($move.substr(0, 1)) - ord('a');

            flunk_move 'Not your spot'
                unless @colors[$row][$column] == 0|$color;
        }

        when $lintel_move {
            my $row_1    = $move.substr(1, 1) - 1;
            my $column_1 = ord($move.substr(0, 1)) - ord('a');
            my $row_2    = $move.substr(4, 1) - 1;
            my $column_2 = ord($move.substr(3, 1)) - ord('a');

            my $row_diff    = abs($row_1 - $row_2);
            my $column_diff = abs($column_1 - $column_2);

            flunk_move 'Must be exactly two cells apart'
                unless $row_diff == 2 && $column_diff == 0
                    || $row_diff == 0 && $column_diff == 2;

            flunk_move 'Must be supported at both ends'
                unless @heights[$row_1][$column_1]
                    == @heights[$row_2][$column_2];

            my $row_m    = ($row_1    + $row_2   ) / 2;
            my $column_m = ($column_1 + $column_2) / 2;
        
            flunk_move 'There is a piece in the way in the middle'
                unless @heights[$row_m][$column_m]
                    <= @heights[$row_1][$column_1];

            flunk_move 'No lintels on the ground'
                unless @heights[$row_1][$column_1];

            my $number_of_samecolor_supporting_pieces
                = (@colors[$row_1][$column_1] == $color ?? 1 !! 0)
                + (@colors[$row_2][$column_2] == $color ?? 1 !! 0);

            if @heights[$row_m][$column_m] == @heights[$row_1][$column_1] { 
                $number_of_samecolor_supporting_pieces
                    += @colors[$row_m][$column_m] == $color ?? 1 !! 0;
            }

            flunk_move 'Must be at least two of your pieces under a lintel'
                if $number_of_samecolor_supporting_pieces < 2;
        }

        default {
            flunk_move 'Nasty syntax';
        }
    }

    return $move;
}

# Prints the 3D game board and the two smaller sub boards, reflecting the
# current state of the game.
sub print_board_view(@layers, @colors, @heights) {

    my $board = $empty_board;

    for @layers.kv -> $height, $layer {
        for $layer.kv.reverse -> $line, $row {
            for $line.kv.reverse -> $cell, $column {

                my $move
                    = chr($column + ord('a')) ~ ($row+1) ~ '-' ~ $height;

                $board = do given $cell {
                    when 1  { put( $v_piece, $board, $move ) }
                    when 2  { put( $h_piece, $board, $move ) }
                    default { $board }
                };
            }
        }
    }

    print $board;

    print_colors_and_heights(@colors, @heights);
}

# Analyzes a given move of a piece of a given color, and makes the appropriate
# changes to the given game state data structures. This sub assumes that the
# move is valid.
sub make_move($move, $color, @layers is rw, @colors is rw, @heights is rw) {

    my @pieces_to_put;

    given $move {
        when $sarsen_move {
            my $row = $move.substr(1, 1) - 1;
            my $column = ord($move.substr(0, 1)) - ord('a');
            my $height = @heights[$row][$column];

            @pieces_to_put = $height, $row, $column;
        }

        when $lintel_move {
            my $row_1    = $move.substr(1, 1) - 1;
            my $column_1 = ord($move.substr(0, 1)) - ord('a');
            my $height   = @heights[$row_1][$column_1];
            my $row_2    = $move.substr(4, 1) - 1;
            my $column_2 = ord($move.substr(3, 1)) - ord('a');
            my $row_m    = ($row_1    + $row_2   ) / 2;
            my $column_m = ($column_1 + $column_2) / 2;

            @pieces_to_put = $height, $row_1, $column_1,
                             $height, $row_m, $column_m,
                             $height, $row_2, $column_2;
        }

        default { die "Nasty syntax."; }
    }

    for @pieces_to_put -> $height, $row, $column {

        if $height >= @layers {
            push @layers, [map { [map { 0 }, ^8] }, ^8];
        }
        @layers[$height][$row][$column]
            = @colors[$row][$column]
            = $color;
        @heights[$row][$column] = $height + 1;
    }
}

# RAKUDO: Would like to make this class local to move_was_winning, using
# 'my class', but that is not implemented yet.
class Pos {
    has $.row    is rw;
    has $.column is rw;
    method Str { join ',', $.row, $.column }
}

# Starting from the last move made, traces the chains to determine whether
# the two sides have been connected.
sub move_was_winning($move, @colors) {

    my $row    = $move.substr(1, 1) - 1;
    my $column = ord($move.substr(0, 1)) - ord('a');

    # Yes, there are lintel moves, but we don't have to special-case those.
    my @pos_queue = Pos.new( :row($row), :column($column) );

    my $last_color = @colors[$row][$column];
    my $size = +@colors;

    my &above = { .row    < $size - 1 && .clone( :row(.row + 1)       ) };
    my &below = { .row    > 0         && .clone( :row(.row - 1)       ) };
    my &right = { .column < $size - 1 && .clone( :column(.column + 1) ) };
    my &left  = { .column > 0         && .clone( :column(.column - 1) ) };

    my %visited;
    my $reached_one_end   = False;
    my $reached_other_end = False;

    # I can't quite figure out why, but debug statements reveal that the
    # loops test the initial position twice, despite the fact that it's only
    # added to the array once.
    while shift @pos_queue -> $pos {
        ++%visited{~$pos};

        for &above, &below, &right, &left -> &direction {
            my $r = $pos.row;
            my $c = $pos.column;
            if direction($pos) -> $neighbor {

                if !%visited.exists(~$neighbor)
                   && @colors[$neighbor.row][$neighbor.column] == $last_color {

                    push @pos_queue, Pos.new( :row($neighbor.row),
                                              :column($neighbor.column) );
                }
            }
            # RAKUDO: Need to restore the values of $pos this way as long as
            # the .clone bug persists.
            $pos.row = $r;
            $pos.column = $c;
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

# Returns a string containing an ASCII picture of an empty druid board of the
# given size.
sub make_empty_board($size) {
    return join "\n", gather {
        take '';
        take my $heading
            = join '',
              '   ',
              map { "   $_  " },
              map { chr($_+ord('A')) },
              ^$size;
        take my $line
            = join '', '   ', '+-----' x $size, '+';
        for (1..$size).reverse -> $r {
            take join '',
                 (sprintf '%2d |', $r),
                 '      ' x ($size) - 1,
                 "     | $r";
            take join '', '   |', '      ' x ($size) - 1,  '     |';
            if $r > 1 {
                take join '', '   +', '     +' x $size;
            }
        }
        take $line;
        take $heading;
        take '';
    };
}
        

my $board_size = 8;
my $empty_board = make_empty_board($board_size);

my $v_piece = '
 +-----+
/|#v#v#|
||#v#v#|
|+-----+
/-----/
';

my $h_piece = '
 +-----+
/|#h#h#|
||#h#h#|
|+-----+
/-----/
';

my $sarsen_move = /^ <[a..h]><[1..8]> $/;
my $lintel_move = /^ <[a..h]><[1..8]> '-' <[a..h]><[1..8]> $/;

# A three-dimensional array. Each item is a layer in on the board, starting
# from the ground. The number of elements in this array always corresponds to
# the height of a highest stone on the board.
my @layers;
# A two-dimensional array. Records the height of the highest stone on each
# location.
# RAKUDO: 0 xx 8 doesn't clone value types
my @heights = map { [map { 0 }, ^8] }, ^8;
# A two-dimensional array. Records the color of the highest stone on each
# location.
my @colors = map { [map { 0 }, ^8] }, ^8;

.say for '(0) Human versus human',
         '(1) Computer versus human',
         '(2) Human versus computer';
repeat {
    print '> ';
} until (my $play_mode = =$*IN) == any(0..2);

loop {
    for <Vertical Horizontal> Z $v_piece, $h_piece Z 1, 2 -> $player,
                                                             $piece,
                                                             $color {

        my $move;
        if $color +& $play_mode { # This player is controlled by the computer
            my ($row, $column);
            repeat {
                $row    = (^8).pick[0];
                $column = (^8).pick[0];
            } until @colors[$row][$column] == 0 | $color;
            $move = chr(ord('a')+$column) ~ ($row+1);

            say "Computer moves $move";
        }
        else {
            print_board_view(@layers, @colors, @heights);

            repeat {
                print "\n", $player, ': '
            } until $move = input_valid_move(@heights, @colors, $color);
        }

        make_move($move, $color, @layers, @colors, @heights);

        if move_was_winning($move, @colors) {
            print_board_view(@layers, @colors, @heights);
            print "\n";

            say "$player won.";
            exit(0);
        }
    }
}

# vim: filetype=perl6
