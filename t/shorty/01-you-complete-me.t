use Test;
use Druid::Player::Computer::Shorty;

plan 9;

sub assert(:$that!, :$yields!, :$desc = '') {
    my $game = Druid::Game.new(:size(3));
    my $shorty = Druid::Player::Computer::Shorty.new(:$game, :color(1));
    my $move = $shorty.choose_move();
    is($move, $yields, $desc);
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
