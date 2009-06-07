use v6;

use Druid::Game;
use Druid::View;

=begin SUMMARY
A textual view of a C<Druid::Game>. Draws a large isometric 3D view, with
the pieces rendered as ASCII blocks, and two smaller 2D views giving
information about the colors and heights of the pieces on the board.
=end SUMMARY

class Druid::View::Text is Druid::View {

    has $!cached-board;

    my $v-piece = '
 +-----+
/|#v#v#|
||#v#v#|
|+-----+
/-----/
';

    my $h-piece = '
 +-----+
/|#h#h#|
||#h#h#|
|+-----+
/-----/
';

    my $cover-right = '
        
       #
       #
';

    my $cover-top = '
  #####
';

    my $cover-top-right = '
       #
';

=begin METHOD
Returns a string containing an ASCII picture of an empty Druid board of
the given size. 
=end METHOD
    sub make-empty-board($size) { 
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

    # RAKUDO: This could be done with BUILD instead, as soon as BUILD can
    #         access private attributes. [perl #64388]
    method new(Druid::Game :$game!) {
        my $view = self.bless( self.CREATE(),
                               :$game,
                               :cached-board(make-empty-board($game.size)) );
        $game.attach($view);
        return $view;
    }

=begin METHOD
Prints the 3D game board and the two smaller sub-boards, reflecting the
current state of the game.
=end METHOD
    method show() {
        .print for $!cached-board, self.colors-and-heights();
    }

=begin METHOD
Returns the 3D game board and the two smaller sub-boards, reflecting the
current state of the game.
=end METHOD
    method Str() {
        return [~] $!cached-board, self.colors-and-heights();
    }

    method build-layers($board is copy, $from) {
        # RAKUDO: Something strange happens when passing Ints as parameters
        my $from-copy = +$from;
        # RAKUDO: Something about array indices and list context
        my @layers = $from-copy == @.layers.end
                        ?? @.layers[$from-copy]
                        !! @.layers[$from-copy .. @.layers.end];
        for @layers.kv -> $relheight, $layer {
            my $height = $relheight + $from-copy;
            for $layer.kv.reverse -> $line, $row {
                for $line.kv.reverse -> $cell, $column {

                    next if $cell == 0;

                    given ($v-piece, $h-piece)[$cell-1] -> $piece {
                        $board = put( $piece, $board, $height, $row, $column );
                        if $column < $.size - 1
                           && $layer[$row][$column] == $layer[$row][$column+1] {
                            $board = put( $cover-right, $board,
                                          $height, $row, $column );
                        }
                        if $row < $.size - 1
                           && $layer[$row][$column] == $layer[$row+1][$column] {
                            $board = put( $cover-top, $board,
                                          $height, $row, $column );
                        }
                        if $row & $column < $.size - 1
                           && $layer[$row][$column]
                              == $layer[$row+1][$column]
                              == $layer[$row][$column+1]
                              == $layer[$row+1][$column+1] {
                            $board = put( $cover-top-right, $board,
                                          $height, $row, $column );
                        }
                    }
                }
            }
        }

        return $board;
    }

=begin SUBROUTINE
Given a string representing a piece and one representing the board,
returns a new board with the piece inserted into some coordinates. This
sub assumes that pieces are drawn in an order that makes sense, so that
pieces in front cover those behind.
=end SUBROUTINE
    sub put($piece, $board, $height, $row, $column) {
        my @lines = $board.split("\n");

        my $coord-line = +@lines - 8 - 3 * $row - $height;

        return put($piece, "\n" ~ $board, $height, $row, $column)
            if $coord-line < 0;

        my $coord-column = 3 + 6 * $column + $height;

        for $piece.split("\n").kv -> $line-no, $piece-line {
            my $board-line = @lines[$coord-line + $line-no];
            @lines[ $coord-line + $line-no ]
                = merge($board-line, $piece-line, $coord-column);
        }

        return @lines.join("\n");
    }

=begin SUBROUTINE
Given a string (assumed to contain no newlines), replaces a section of
that string, starting from $column, with the contents of $new.
When replacing characters, two excpetions are made:
=for item
    spaces in $new are treated as 'transparent', so that they
    don't replace the old character,
=for item
    octothorpes '#' insert actual spaces, i.e. act as a sort of
    escape character for spaces.
=end SUBROUTINE
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

=begin METHOD
Prints two smaller boards representing
=item who owns each location, and
=item how many stones have been piled on each location.
=end METHOD
    method colors-and-heights() {

        my &from-pretty    = { $^pretty.trans( ['>>',   '<<', '.']
                                            => ['%2d','%-2d','%s'] ) };

        my &format-colors  = { <. v h>[$^color] };
        my &format-heights = { $^height || '.' };

        my $letters = 'A'..chr(ord('A') + $.size - 1);

        my $inter-board-space
            = ' ' x (1 + 6*$.size - 2*$.size - 2*($.size-1) - 14);
        my $board-line = [~] '>>  ', ('.' xx $.size).join(' '), '  <<';

        my $footer = [~] "\n      ", $letters.join(' '),
                         ' ' x 8, $inter-board-space,
                         $letters.join(' '), "\n";
        my $header = "$footer\n";

        return gather {
            take $header;
            # RAKUDO: .reverse on Ranges out of order. [perl #64458]
            for (1..$.size).list.reverse -> $row {
                take sprintf from-pretty(
                        [~] '  ', $board-line, $inter-board-space, $board-line
                    ),
                    $row, (map &format-colors,  @.colors[$row-1].values),  $row,
                    $row, (map &format-heights, @.heights[$row-1].values), $row;
                take "\n";
            }
            take $footer;
        };
    }

    method add-piece($height, $row, $column, $color) {
        $!cached-board = self.build-layers($!cached-board, $height);
    }
}

# vim: filetype=perl6
