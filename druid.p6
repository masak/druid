#!perl6

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

my $empty_board = '
      A     B     C     D     E     F     G     H
   +-----+-----+-----+-----+-----+-----+-----+-----+
 8 |                                               | 8
   |                                               |
   +     +     +     +     +     +     +     +     +
 7 |                                               | 7
   |                                               |
   +     +     +     +     +     +     +     +     +
 6 |                                               | 6
   |                                               |
   +     +     +     +     +     +     +     +     +
 5 |                                               | 5
   |                                               |
   +     +     +     +     +     +     +     +     +
 4 |                                               | 4
   |                                               |
   +     +     +     +     +     +     +     +     +
 3 |                                               | 3
   |                                               |
   +     +     +     +     +     +     +     +     +
 2 |                                               | 2
   |                                               |
   +     +     +     +     +     +     +     +     +
 1 |                                               | 1
   |                                               |
   +-----+-----+-----+-----+-----+-----+-----+-----+
      A     B     C     D     E     F     G     H
';

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

my @layers;
# RAKUDO: 0 xx 8 doesn't clone value types
my @heights = map { [map { 0 }, ^8] }, ^8;
my @colors = map { [map { 0 }, ^8] }, ^8;

loop {
    for <Vertical Horizontal> Z $v_piece, $h_piece Z 1, 2 -> $player,
                                                             $piece,
                                                             $color {

        print_board_view(@layers, @colors, @heights);

        repeat {
            print "\n", $player, ': '
        } until my $move = input_valid_move(@heights, @colors, $color);

        make_move($move, $color, @layers, @colors, @heights);
    }
}
