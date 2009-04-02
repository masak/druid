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
}

# vim: filetype=perl6
