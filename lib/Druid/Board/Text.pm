use v6;

use Druid::Board;

class Druid::Board::Text is Druid::Board {

    has $!size is readonly; # if you want a new size, make a new object
    has @!layers;
    has @!colors;
    has @!heights;

    has $!empty_board is rw;

    regex col_letter { <[a..z]> }
    regex row_number { \d+ }
    regex coords { <col_letter><row_number> }

    my $sarsen_move = /^ <coords> $/;
    my $lintel_move = /^ <coords> '-' <coords> $/;

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

    # Returns a string containing an ASCII picture of an empty druid board of
    # the given size. 
    sub make_empty_board($size) { 
        return join "\n", gather { 
            take ''; 
            take my $heading 
                = [~] '   ', map {"   $_  "}, map {chr($_+ord('A'))}, ^$size; 
            take my $line = [~] '   ', '+-----' x $size, '+'; 
            for (1..$size).reverse -> $r { 
                take [~] (sprintf '%2d |', $r),
                         '      ' x ($size) - 1,
                         "     | $r";
                take [~] '   |', '      ' x ($size) - 1,  '     |'; 
                if $r > 1 { 
                    take [~] '   +', '     +' x $size; 
                } 
            } 
            take $line; 
            take $heading; 
            take ''; 
        }; 
    } 

    method init() {
        die "Forbidden size: $!size"
            unless 3 <= $!size <= 26;

        $!empty_board = make_empty_board($!size);
        @!heights = map { [ 0 xx $!size ] }, ^$!size;
        @!colors  = map { [ 0 xx $!size ] }, ^$!size;
    }

    # Prints the 3D game board and the two smaller sub boards, reflecting the
    # current state of the game.
    method show() {

        # RAKUDO: BUILD
        $!empty_board // self.init();
        my $board = $!empty_board;

        for @!layers.kv -> $height, $layer {
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

        self.print_colors_and_heights();
    }

    # Given a string representing a piece and one representing the board,
    # returns a new board with the piece inserted into some coordinates. This
    # sub assumes that pieces are drawn in an order that makes sense, so that
    # pieces in front cover those behind.
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

    # Given a string (assumed to contain no newlines), replaces a section of
    # that string, starting from $column, with the contents of $new_section.
    # When replacing characters, two excpetions are made:
    #  (1) spaces in $new_section are treated as 'transparent', so that they
    #      don't replace the old character,
    #  (2) octothorpes '#' insert actual spaces, i.e. act as a sort of
    #      escape character for spaces.
    sub merge($old, $new, $start) {
        my @old = $old.split('');
        my @new = $new.split('');

        # RAKUDO: xx and push don't seem to work as advertised.
        push @old, ' ' for ^($start + $new.chars - $old.chars);

        for @new.kv -> $i, $char {
            @old[$start + $i] = $char unless $char eq ' ';
            @old[$start + $i] = ' ' if $char eq '#'
        }

        return @old.join('');
    }

    # Prints two smaller boards representing (1) who owns each location, and
    # (2) how many stones have been piled on each location.
    method print_colors_and_heights() {

        my &from_pretty    = { $^pretty.trans( ['>>',   '<<', '.']
                                            => ['%2d','%-2d','%s'] ) };

        my &format_colors  = { <. v h>[$^color] };
        my &format_heights = { $^height || '.' };

        my $letters = 'A'..chr(ord('A') + $!size - 1);

        my $inter_board_space
            = ' ' x (1 + 6*$!size - 2*$!size - 2*($!size-1) - 14);
        my $board_line = [~] '>>  ', ('.' xx $!size).join(' '), '  <<';

        my $footer = [~] "\n      ", $letters.join(' '),
                         ' ' x 8, $inter_board_space,
                         $letters.join(' '), "\n";
        my $header = "$footer\n";

        print $header;
        for (1..$!size).reverse -> $row {
            say sprintf from_pretty(
                    [~] '  ', $board_line, $inter_board_space, $board_line
                ),
                $row, (map &format_colors,  @!colors[$row-1].values),  $row,
                $row, (map &format_heights, @!heights[$row-1].values), $row;
        }
        print $footer;
    }

    # Analyzes a given move of a piece of a given color, and makes the
    # appropriate changes to the given game state data structures. This method
    # assumes that the move is valid and within boundaries.
    method make_move($move, $color) {
        my @pieces_to_put;

        given $move {
            when $sarsen_move {
                my $row = $<coords><row_number> - 1;
                my $column = ord($<coords><col_letter>) - ord('a');
                my $height = @!heights[$row][$column];

                @pieces_to_put = $height, $row, $column;
            }

            when $lintel_move {
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
        }
    }

}
