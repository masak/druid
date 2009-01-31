use v6;

class Druid::Player::Computer is Druid::Player {
    method choose_move() {
        my ($row, $column);
        repeat {
            $row    = (^$.size).pick[0];
            $column = (^$.size).pick[0];
        } until $.colors[$row][$column] == 0 | $!color;

        my $move = chr(ord('a')+$column) ~ ($row+1);

        say '';
        say "The computer moves $move";
        return $move;
    }
}
