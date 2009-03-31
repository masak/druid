use v6;

class Druid::Base {
    regex col_letter { <[a..z]> }
    regex row_number { \d+ }
    regex coords { <col_letter><row_number> }

    our $.sarsen_move = /^ <coords> $/;
    our $.lintel_move = /^ <coords> '-' <coords> $/;
    our $.pass = /^ ['pass' | 'p'] $/;
}

# vim: filetype=perl6
