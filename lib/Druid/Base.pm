# = Base class collecting ambient regexes, attributes and methods.
grammar Druid::Move {
    # RAKUDO: Cannot use dashes here. [perl #64464]
    regex col_letter { <[a..z]> }
    regex row_number { \d+ }
    regex coords { <col_letter><row_number> }

    regex sarsen-move { ^ <coords> $ }              # = A sarsen (length 1) move
    regex lintel-move { ^ <coords> '-' <coords> $ } # = A lintel (length 3) move
    regex pass     { ['pass'   | 'p'] $ }           # = A passing (no-op) move
    regex swap     { ['swap'   | 's'] $ }           # = A swap move
    regex resign   { ['resign' | 'r'] $ }           # = A forfeit
}

class Druid::Base {
    # = Returns (zero-based) row and column, given a C<Match> object
    method extract-coords(Match $m) {
        my Int $row    = $m<row_number> - 1;
        my Int $column = ord($m<col_letter>) - ord('a');

        return ($row, $column);
    }
}

# vim: filetype=perl6
