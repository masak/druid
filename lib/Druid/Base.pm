use v6;

class Druid::Base {
    regex col_letter { <[a..z]> }
    regex row_number { \d+ }
    regex coords { <col_letter><row_number> }

    our $.sarsen_move = /^ <coords> $/;
    our $.lintel_move = /^ <coords> '-' <coords> $/;
    our $.pass   = /^ ['pass'   | 'p'] $/;
    our $.swap   = /^ ['swap'   | 's'] $/;
    our $.resign = /^ ['resign' | 'r'] $/;

    method extract-coords(Match $m) {
        # RAKUDO: Hoping these explicit int(...) conversions won't be
        #         necessary in the long run.
        my Int $row    = int($m<row_number> - 1);
        my Int $column = int(ord($m<col_letter>) - ord('a'));
    }
}

# vim: filetype=perl6
