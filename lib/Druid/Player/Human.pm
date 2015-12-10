use v6;
use Druid::Player;

#| A human player, i.e. a C<Druid::Player> whose moves are typed in on C<$*IN>
#| by a human.
unit class Druid::Player::Human is Druid::Player;

method choose-move() {
    do Whatever until my $move = self.input-valid-move();
    return $move;
}

method input-valid-move() {
    my $move = prompt("\n{self}: ");
    say '' and exit(1) if $*IN.eof;

    if $.game.is-move-bad($move) -> $reason {
        say $reason;
        return;
    }

    return $move;
}

# vim: filetype=perl6
