use Test;
use Druid::Player::Computer::Shorty;

plan 9;

sub pieces($board) {
    my @result;
    my $board_new = $board.subst(/\s+/, '');
    my $size = +$board_new.split("\n");
    for $board_new.split("\n").kv -> $row, $line {
        for $line.subst(/\s+/, '').split('').kv -> $column, $cell {
            if $cell eq 'V' {
                push @result, chr(ord('a')+$column)~($size-$row), 1;
            }
        }
    }
    return @result;
}

# RAKUDO: Unable to rename named params with parens
sub assert(:$that!, :$yields!, :$desc = '') {
    my $input = $that;
    my $expected = $yields;
    my $size = +$input.subst(/\s+/, '').split("\n");
    my $game = Druid::Game.new(:size($size));
    $game.init();
    for pieces($input) -> $pos, $player {
        $game.make_move($pos, $player);
    }
    my $shorty = Druid::Player::Computer::Shorty.new(:$game, :color(1));
    my $received = $shorty.choose_move();
    is($received, $expected, $desc);
}

{
    my $board = '
        .V.
        .V.
        ...';
    assert :that($board), :yields<b1>, :desc('Go for the missing link');
}

{
    my $board = '
        .V.
        ...
        ...';
    assert :that($board), :yields<b1>, :desc('Be bold and jump far');
}

{
    my $board = '
        ...
        HH.
        ...';
    assert :that($board), :yields<c2>, :desc('Fight against the missing link');
}

{
    my $board = '
        ..V..
        .....
        .....
        .....
        ..V..';
    assert :that($board), :yields<c3>, :desc('Bidirectional boldness');
}

{
    my $board = '
        .....
        .....
        H...H
        .....
        .....';
    assert :that($board), :yields<c3>, :desc('Bidirectional defense');
}

{
    my $board = '
        ..V..
        .....
        ..V..
        HHV..
        ..V..';
    assert :that($board), :yields<c4>, :desc('Go for the quick win');
}

{
    my $board = '
        ..V..
        .....
        ..V..
        .....
        HHV..';
    assert :that($board), :yields<c1>, :desc('Defense before offense');
}

{
    my $board = '
        .V...
        .V...
        .HV..
        .....
        ..V..';
    assert :that($board), :yields<c2>, :desc('A corner can matter a lot');
}

{
    my $board = '
        .V...
        .V...
        ..V..
        ..V..
        .....';
    assert :that($board), :yields<c1>, :desc('Cutting corners');
}
