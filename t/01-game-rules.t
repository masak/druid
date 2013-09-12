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

my &*before = sub {
    my Druid::Game $game .= new(:size(3));
    # XXX: Maybe we should mock these instead of depending on Druid::Player.
    my Druid::Player ($player1, $player2)
        = map { Druid::Player.new(:game($game), :color($_)) }, 1, 2;

    return ($game, $player1, $player2);
}

my &*the-player-to-move-is-vertical-at-the-beginning-of-the-game = sub {
    is $^game.player-to-move, 1,
       "the player to move is vertical at the beginning of the game";
}

my &*the-player-to-move-is-horizontal-after-the-first-move = sub {
    $^game.make-move('a1');
    is $game.player-to-move, 2,
        "the player to move is horizontal after the first move";
}

my &*the-player-to-move-alternates-with-every-move = sub {
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

my &*a-sarsen-move-must-have-a-certain-syntax = sub {
    ok (!defined $^game.make-move("1a")),
        "a sarsen move must have a certain syntax";
}

my &*a-sarsen-move-must-be-within-the-limits-of-the-board = sub {
    ok (!defined $^game.make-move("a5")),
        "a sarsen move must be within the limits of the board";
}

my &*a-sarsen-move-can-be-made-directly-on-the-ground = sub {
    ok (defined $^game.make-move("b2")),
        "a sarsen move can be made directly on the ground";
}

my &*a-sarsen-move-can-be-made-on-top-of-the-same-color = sub {
    $^game.make-move($_) for <b2 a1>;
    ok (defined $game.make-move("b2")),
        "a sarsen move can be made on top of the same color";
}

my &*a-sarsen-move-can-not-be-made-on-top-of-another-color = sub {
    $^game.make-move($_) for <b2 a1>;
    ok (!defined $game.make-move("a1")),
        "a sarsen move can not be made on top of another color";
}

my &*a-lintel-move-must-have-a-certain-syntax = sub {
    ok (!defined $^game.make-move("a3-3c")),
        "a lintel move must have a certain syntax";
}

my &*a-lintel-move-must-be-within-the-limits-of-the-board = sub {
    ok (!defined $^game.make-move("a4-c4")),
        "a lintel move must be within the limits of the board";
}

my &*a-lintel-move-can-not-be-made-directly-on-the-ground = sub {
    ok (!defined $^game.make-move("a1-c1")),
        "a lintel move can not be made directly on the ground";
}

my &*a-lintel-move-must-be-made-two-units-apart = sub {
    $^game.make-move($_) for <a1 a3 b1>;
    ok (!defined $game.make-move("a1-b1")),
        "a lintel move must be made two units apart";
}

my &*a-lintel-move-must-have-support-at-both-ends = sub {
    $^game.make-move($_) for <a1 a3>;
    ok (!defined $game.make-move("a1-c1")),
        "a lintel move must have support at both ends";
}

my &*a-lintel-move-can-not-have-less-than-two-friendly-stones-under-it = sub {
    $^game.make-move($_) for <a1 b1 a3 c1>;
    ok (!defined $game.make-move('a1-c1')),
        "a lintel move can not have less than two friendly stones under it";
}

my &*a-lintel-move-can-not-have-more-than-two-friendly-stones-under-it = sub {
    $^game.make-move($_) for <a1 a3 b1 b3 c1 c3>;
    ok (!defined $game.make-move('a1-c1')),
        "a lintel move can not have more than two friendly stones under it";
}

my &*a-lintel-move-can-form-a-bridge = sub {
    $^game.make-move($_) for <a2 a1 c2 c1>;
    ok (defined $game.make-move('a2-c2')), "a lintel move can form a bridge";
}

my &*a-lintel-move-can-claim-enemy-territory = sub {
    $^game.make-move($_) for <a1 a3 b1 c1>;
    ok (defined $game.make-move('a1-c1')),
        "a lintel move can claim enemy territory";
}

my &*swapping-is-allowed-as-the-second-move = sub {
    $^game.make-move('a1');
    ok (defined $game.make-move('swap')),
        "swapping is allowed as the second move";
}

my &*swapping-is-not-allowed-as-the-first-move = sub {
    ok (!defined $^game.make-move('swap')),
        "swapping is not allowed as the first move";
}

my &*swapping-is-not-allowed-after-the-second-move = sub {
    $^game.make-move($_) for <a1 a2>;
    ok (!defined $^game.make-move('swap')),
        "swapping is not allowed after the second move";
}

my &*swapping-exchanges-the-colors-of-the-players = sub {
    $^game.make-move($_) for <a1 swap>;
    ok $^player1.color == 2 && $^player2.color == 1,
        "swapping exchanges the colors of the players";
}

my &*swapping-makes-it-the-second-player's-turn-again = sub {
    $^game.make-move($_) for <a1 swap>;
    is $game.player-to-move, 2,
        "swapping makes it the second player's turn again";
}

my &*passing-does-not-change-the-board = sub {
    $^game.make-move($_) for <a2 b3 c1 b3>;
    my @heights-snapshot = $game.heights;
    my @colors-snapshot  = $game.colors;
    $game.make-move('pass');
    ok @heights-snapshot eqv $game.heights
       || @colors-snapshot eqv $game.colors,
        "passing does not change the board";
}

my &*passing-makes-it-the-other-player's-turn = sub {
    $^game.make-move('pass');
    is $game.player-to-move, 2,
        "passing makes it the other player's turn";
}

my &*passing-twice-ends-the-game = sub {
    $^game.make-move($_) for <pass pass>;
    ok $game.finished, "passing twice ends the game";
}

my &*resigning-must-have-a-certain-syntax = sub {
    ok (defined $^game.make-move('resign')),
        "resigning must have a certain syntax";
}

my &*resigning-does-not-change-the-board = sub {
    $^game.make-move($_) for <a2 b3 c1 b3>;
    my @heights-snapshot = $game.heights;
    my @colors-snapshot  = $game.colors;
    $game.make-move('resign');
    ok @heights-snapshot eqv $game.heights
       || @colors-snapshot eqv $game.colors,
        "resigning does not change the board";
}

my &*resigning-ends-the-game = sub {
    $^game.make-move('resign');
    ok $game.finished, "resigning ends the game";
}

my &*a-chain-wins-the-game-if-it-connects-a-player's-edges = sub {
    $^game.make-move($_) for <b1 b2 c1 b2 c2 b2 c3>;
    ok $game.finished,
        "a chain wins the game if it connects a player's edges";
}

my &*a-chain-does-not-win-the-game-if-it-connects-the-enemy's-edges = sub {
    $^game.make-move($_) for <a2 b1 b2 b1 c2>;
    ok !$game.finished,
        "a chain does not win the game if it connects the enemy's edges";
}

plan count-tests(@tests);
run-tests(@tests);

# vim: filetype=perl6
