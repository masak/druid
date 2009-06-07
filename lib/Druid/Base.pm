use v6;

=begin SUMMARY
C<Druid::Base> is the base class of most other Druid classes, collecting
regexes, attributes and methods which most of these other classes need.
=end SUMMARY

class Druid::Base {
    # RAKUDO: Cannot use dashes here. [perl #64464]
    regex col_letter { <[a..z]> }
    regex row_number { \d+ }
    regex coords { <col_letter><row_number> }

    our $.sarsen-move = /^ <coords> $/;
    our $.lintel-move = /^ <coords> '-' <coords> $/;
    our $.pass   = /^ ['pass'   | 'p'] $/;
    our $.swap   = /^ ['swap'   | 's'] $/;
    our $.resign = /^ ['resign' | 'r'] $/;

    method extract-coords(Match $m) {
        # RAKUDO: Hoping these explicit int(...) conversions won't be
        #         necessary in the long run.
        my Int $row    = int($m<row_number> - 1);
        my Int $column = int(ord($m<col_letter>) - ord('a'));

        return ($row, $column);
    }
}

# vim: filetype=perl6
