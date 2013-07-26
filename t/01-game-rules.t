use v6;
use Test::Ix;
use Test;
use Druid::Game;
use Druid::Player;

my @tests =
    'the player to move' => [
        'is vertical at the beginning of the game',
        'is horizontal after the first move',
        'alternates with every move',
    ],
    'a sarsen move' => [
        'must have a certain syntax',
        'must be within the limits of the board',
        'can be made directly on the ground',
        'can be made on top of the same color',
        'can not be made on top of another color',
    ],
    'a lintel move' => [
        'must have a certain syntax',
        'must be within the limits of the board',
        'can not be made directly on the ground',
        'must be made two units apart',
        'must have support at both ends',
        'can not have less than two friendly stones under it',
        'can not have more than two friendly stones under it',
        'can form a bridge',
        'can claim enemy territory',
    ],
    'swapping' => [
        'is allowed as the second move',
        'is not allowed as the first move',
        'is not allowed after the second move',
        'exchanges the colors of the players',
        "makes it the second player's turn again",
    ],
    'passing' => [
        'does not change the board',
        "makes it the other player's turn",
        'twice ends the game',
    ],
    'resigning' => [
        'must have a certain syntax',
        'does not change the board',
        'ends the game',
    ],
    'a chain' => [
        "wins the game if it connects a player's edges",
        "does not win the game if it connects the enemy's edges",
    ]
;

plan count-tests(@tests);
run-tests(@tests);

our sub before {
    my Druid::Game $game .= new(:size(3));
    # XXX: Maybe we should mock these instead of depending on Druid::Player.
    my Druid::Player ($player1, $player2)
        = map { Druid::Player.new(:game($game), :color($_)) }, 1, 2;

    return ($game, $player1, $player2);
}

our sub the-player-to-move-is-vertical-at-the-beginning-of-the-game {
    is $^game.player-to-move, 1,
       "the player to move is vertical at the beginning of the game";
}

our sub the-player-to-move-is-horizontal-after-the-first-move {
    $^game.make-move('a1');
    is $game.player-to-move, 2,
        "the player to move is horizontal after the first move";
}

our sub the-player-to-move-alternates-with-every-move {
    $^game; # must mention it outside of the gather
    my @move-order = gather for ^10 {
        take 0+$game.player-to-move;
        $game.make-move('a1');
        take 0+$game.player-to-move;
        $game.make-move('b1');
    };
    is @move-order, [(1, 2) xx 10],
        "the player to move alternates with every move";
}

our sub a-sarsen-move-must-have-a-certain-syntax {
    ok (!defined $^game.make-move("1a")),
        "a sarsen move must have a certain syntax";
}

our sub a-sarsen-move-must-be-within-the-limits-of-the-board {
    ok (!defined $^game.make-move("a5")),
        "a sarsen move must be within the limits of the board";
}

our sub a-sarsen-move-can-be-made-directly-on-the-ground {
    ok (defined $^game.make-move("b2")),
        "a sarsen move can be made directly on the ground";
}

our sub a-sarsen-move-can-be-made-on-top-of-the-same-color {
    $^game.make-move($_) for <b2 a1>;
    ok (defined $game.make-move("b2")),
        "a sarsen move can be made on top of the same color";
}

our sub a-sarsen-move-can-not-be-made-on-top-of-another-color {
    $^game.make-move($_) for <b2 a1>;
    ok (!defined $game.make-move("a1")),
        "a sarsen move can not be made on top of another color";
}

our sub a-lintel-move-must-have-a-certain-syntax {
    ok (!defined $^game.make-move("a3-3c")),
        "a lintel move must have a certain syntax";
}

our sub a-lintel-move-must-be-within-the-limits-of-the-board {
    ok (!defined $^game.make-move("a4-c4")),
        "a lintel move must be within the limits of the board";
}

our sub a-lintel-move-can-not-be-made-directly-on-the-ground {
    ok (!defined $^game.make-move("a1-c1")),
        "a lintel move can not be made directly on the ground";
}

our sub a-lintel-move-must-be-made-two-units-apart {
    $^game.make-move($_) for <a1 a3 b1>;
    ok (!defined $game.make-move("a1-b1")),
        "a lintel move must be made two units apart";
}

our sub a-lintel-move-must-have-support-at-both-ends {
    $^game.make-move($_) for <a1 a3>;
    ok (!defined $game.make-move("a1-c1")),
        "a lintel move must have support at both ends";
}

our sub a-lintel-move-can-not-have-less-than-two-friendly-stones-under-it {
    $^game.make-move($_) for <a1 b1 a3 c1>;
    ok (!defined $game.make-move('a1-c1')),
        "a lintel move can not have less than two friendly stones under it";
}

our sub a-lintel-move-can-not-have-more-than-two-friendly-stones-under-it {
    $^game.make-move($_) for <a1 a3 b1 b3 c1 c3>;
    ok (!defined $game.make-move('a1-c1')),
        "a lintel move can not have more than two friendly stones under it";
}

our sub a-lintel-move-can-form-a-bridge {
    $^game.make-move($_) for <a2 a1 c2 c1>;
    ok (defined $game.make-move('a2-c2')), "a lintel move can form a bridge";
}

our sub a-lintel-move-can-claim-enemy-territory {
    $^game.make-move($_) for <a1 a3 b1 c1>;
    ok (defined $game.make-move('a1-c1')),
        "a lintel move can claim enemy territory";
}

our sub swapping-is-allowed-as-the-second-move {
    $^game.make-move('a1');
    ok (defined $game.make-move('swap')),
        "swapping is allowed as the second move";
}

our sub swapping-is-not-allowed-as-the-first-move {
    ok (!defined $^game.make-move('swap')),
        "swapping is not allowed as the first move";
}

our sub swapping-is-not-allowed-after-the-second-move {
    $^game.make-move($_) for <a1 a2>;
    ok (!defined $^game.make-move('swap')),
        "swapping is not allowed after the second move";
}

our sub swapping-exchanges-the-colors-of-the-players {
    $^game.make-move($_) for <a1 swap>;
    ok $^player1.color == 2 && $^player2.color == 1,
        "swapping exchanges the colors of the players";
}

our sub swapping-makes-it-the-second-player's-turn-again {
    $^game.make-move($_) for <a1 swap>;
    is $game.player-to-move, 2,
        "swapping makes it the second player's turn again";
}

our sub passing-does-not-change-the-board {
    $^game.make-move($_) for <a2 b3 c1 b3>;
    my @heights-snapshot = $game.heights;
    my @colors-snapshot  = $game.colors;
    $game.make-move('pass');
    ok @heights-snapshot eqv $game.heights
       || @colors-snapshot eqv $game.colors,
        "passing does not change the board";
}

our sub passing-makes-it-the-other-player's-turn {
    $^game.make-move('pass');
    is $game.player-to-move, 2,
        "passing makes it the other player's turn";
}

our sub passing-twice-ends-the-game {
    $^game.make-move($_) for <pass pass>;
    ok $game.finished, "passing twice ends the game";
}

our sub resigning-must-have-a-certain-syntax {
    ok (defined $^game.make-move('resign')),
        "resigning must have a certain syntax";
}

our sub resigning-does-not-change-the-board {
    $^game.make-move($_) for <a2 b3 c1 b3>;
    my @heights-snapshot = $game.heights;
    my @colors-snapshot  = $game.colors;
    $game.make-move('resign');
    ok @heights-snapshot eqv $game.heights
       || @colors-snapshot eqv $game.colors,
        "resigning does not change the board";
}

our sub resigning-ends-the-game {
    $^game.make-move('resign');
    ok $game.finished, "resigning ends the game";
}

our sub a-chain-wins-the-game-if-it-connects-a-player's-edges {
    $^game.make-move($_) for <b1 b2 c1 b2 c2 b2 c3>;
    ok $game.finished,
        "a chain wins the game if it connects a player's edges";
}

our sub a-chain-does-not-win-the-game-if-it-connects-the-enemy's-edges {
    $^game.make-move($_) for <a2 b1 b2 b1 c2>;
    ok !$game.finished,
        "a chain does not win the game if it connects the enemy's edges";
}

# vim: filetype=perl6
