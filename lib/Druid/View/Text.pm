use v6;

use Druid::Game;
use Druid::View;

class Druid::View::Text is Druid::View {

    has $!cached_board is rw;

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

    my $cover_right = '
        
       #
       #
';

    my $cover_top = '
  #####
';

    my $cover_top_right = '
       #
';

    # Returns a string containing an ASCII picture of an empty druid board of
    # the given size. 
    sub make_empty_board($size) { 
        # The 'join $sep, gather { ... }' pattern allows us to put a long
        # string together, without having to refer to the same variable over
        # and over.
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
#        die 'Must be tied to a game'
# RAKUDO: Protoobjects shouldn't be defined [perl #62894]
#            unless $!game.defined;
# RAKUDO: This doesn't match here [perl #62902]
#            if $!game === Druid::Game;

        # RAKUDO: The following line should be in Druid::View
        $!game.attach(self);
        $!cached_board = make_empty_board($.size);
    }

    # Prints the 3D game board and the two smaller sub boards, reflecting the
    # current state of the game.
    method show() {

        # RAKUDO: BUILD
        $!cached_board // self.init();
        print $!cached_board;

        self.print_colors_and_heights();
    }

    method build_layers($board is copy, $from) {
        # RAKUDO: Something strange happens when passing Ints as parameters
        my $from_copy = +$from;
        # RAKUDO: Something about array indices and list context
        my @layers = $from_copy == @.layers.end
                        ?? @.layers[$from_copy]
                        !! @.layers[$from_copy .. @.layers.end];
        for @layers.kv -> $relheight, $layer {
            my $height = $relheight + $from_copy;
            for $layer.kv.reverse -> $line, $row {
                for $line.kv.reverse -> $cell, $column {

                    next if $cell == 0;

                    given ($v_piece, $h_piece)[$cell-1] -> $piece {
                        $board = put( $piece, $board, $height, $row, $column );
                        if $column < $.size - 1
                           && $layer[$row][$column] == $layer[$row][$column+1] {
                            $board = put( $cover_right, $board,
                                          $height, $row, $column );
                        }
                        if $row < $.size - 1
                           && $layer[$row][$column] == $layer[$row+1][$column] {
                            $board = put( $cover_top, $board,
                                          $height, $row, $column );
                        }
                        if $row & $column < $.size - 1
                           && $layer[$row][$column]
                              == $layer[$row+1][$column]
                              == $layer[$row][$column+1]
                              == $layer[$row+1][$column+1] {
                            $board = put( $cover_top_right, $board,
                                          $height, $row, $column );
                        }
                    }
                }
            }
        }

        return $board;
    }

    # Given a string representing a piece and one representing the board,
    # returns a new board with the piece inserted into some coordinates. This
    # sub assumes that pieces are drawn in an order that makes sense, so that
    # pieces in front cover those behind.
    sub put($piece, $board, $height, $row, $column) {
        my @lines = $board.split("\n");

        my $coord_line = +@lines - 8 - 3 * $row - $height;

        return put($piece, "\n" ~ $board, $height, $row, $column)
            if $coord_line < 0;

        my $coord_column = 3 + 6 * $column + $height;

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

        my $letters = 'A'..chr(ord('A') + $.size - 1);

        my $inter_board_space
            = ' ' x (1 + 6*$.size - 2*$.size - 2*($.size-1) - 14);
        my $board_line = [~] '>>  ', ('.' xx $.size).join(' '), '  <<';

        my $footer = [~] "\n      ", $letters.join(' '),
                         ' ' x 8, $inter_board_space,
                         $letters.join(' '), "\n";
        my $header = "$footer\n";

        print $header;
        for (1..$.size).reverse -> $row {
            say sprintf from_pretty(
                    [~] '  ', $board_line, $inter_board_space, $board_line
                ),
                $row, (map &format_colors,  @.colors[$row-1].values),  $row,
                $row, (map &format_heights, @.heights[$row-1].values), $row;
        }
        print $footer;
    }

    method add_piece($height, $row, $column, $color) {
        $!cached_board = self.build_layers($!cached_board, $height);
    }
}

# vim: filetype=perl6
