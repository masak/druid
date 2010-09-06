# = Base class collecting ambient regexes, attributes and methods.
class Druid::Base;

# RAKUDO: Cannot use dashes here. [perl #64464]
regex col_letter { <[a..z]> }
regex row_number { \d+ }
regex coords { <col_letter><row_number> }

our $.sarsen-move = /^ <coords> $/;              # = A sarsen (length 1) move
our $.lintel-move = /^ <coords> '-' <coords> $/; # = A lintel (length 3) move
our $.pass   = /^ ['pass'   | 'p'] $/;           # = A passing (no-op) move
our $.swap   = /^ ['swap'   | 's'] $/;           # = A swap move
our $.resign = /^ ['resign' | 'r'] $/;           # = A forfeit

# = Returns (zero-based) row and column, given a C<Match> object
method extract-coords(Match $m) {
    # RAKUDO: Hoping these explicit (...).Int conversions won't be
    #         necessary in the long run.
    my Int $row    = ($m<row_number> - 1).Int;
    my Int $column = (ord($m<col_letter>) - ord('a')).Int;

    return ($row, $column);
}

# vim: filetype=perl6
