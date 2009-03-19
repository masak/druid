use v6;
use Test::Ix;
use Druid::Game;

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
        'changes the location of the piece on the board',
        'makes the piece belong to horizontal instead',
        'is allowed as the second move',
        'is not allowed as the first move',
        'is not allowed after the second move',
    ],
    'passing' => [
        'does not change the board',
        "makes it the other player's turn",
    ],
    'resigning' => [
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

sub before {
    my Druid::Game $game .= new(:size(3));
    $game.init();
    return $game;
}

sub the-player-to-move-is-vertical-at-the-beginning-of-the-game($game) {
    is $game.player-to-move, 1,
       "the player to move is vertical at the beginning of the game";
}

sub the-player-to-move-is-horizontal-after-the-first-move($game) {
    $game.make_move('a1', 1);
    is $game.player-to-move, 2,
        "the player to move is horizontal after the first move";
}

sub the-player-to-move-alternates-with-every-move($game) {
    my @move-order = gather for ^10 {
        take 0+$game.player-to-move;
        $game.make_move('a1', 1);
        take 0+$game.player-to-move;
        $game.make_move('b1', 2);
    };
    is @move-order, [(1, 2) xx 10],
        "the player to move alternates with every move";
}

sub a-sarsen-move-must-have-a-certain-syntax($game) {
    ok (eval '$game.make_move("a1", 1)'; !defined $!)
    && (eval '$game.make_move("1a", 2)';  defined $!),
        "a sarsen move must have a certain syntax";
}

sub a-sarsen-move-must-be-within-the-limits-of-the-board($game) {
    dies_ok { $game.make_move("a5", 1) },
        "a sarsen move must be within the limits of the board";
}

sub a-sarsen-move-can-be-made-directly-on-the-ground {
    ok 0, "a sarsen move can be made directly on the ground";
}

sub a-sarsen-move-can-be-made-on-top-of-the-same-color {
    ok 0, "a sarsen move can be made on top of the same color";
}

sub a-sarsen-move-can-not-be-made-on-top-of-another-color {
    ok 0, "a sarsen move can not be made on top of another color";
}

sub a-lintel-move-must-have-a-certain-syntax {
    ok 0, "a lintel move must have a certain syntax";
}

sub a-lintel-move-must-be-within-the-limits-of-the-board {
    ok 0, "a lintel move must be within the limits of the board";
}

sub a-lintel-move-can-not-be-made-directly-on-the-ground {
    ok 0, "a lintel move can not be made directly on the ground";
}

sub a-lintel-move-must-be-made-two-units-apart {
    ok 0, "a lintel move must be made two units apart";
}

sub a-lintel-move-must-have-support-at-both-ends {
    ok 0, "a lintel move must have support at both ends";
}

sub a-lintel-move-can-not-have-less-than-two-friendly-stones-under-it {
    ok 0, "a lintel move can not have less than two friendly stones under it";
}

sub a-lintel-move-can-not-have-more-than-two-friendly-stones-under-it {
    ok 0, "a lintel move can not have more than two friendly stones under it";
}

sub a-lintel-move-can-form-a-bridge {
    ok 0, "a lintel move can form a bridge";
}

sub a-lintel-move-can-claim-enemy-territory {
    ok 0, "a lintel move can claim enemy territory";
}

sub swapping-changes-the-location-of-the-piece-on-the-board {
    ok 0, "swapping changes the location of the piece on the board";
}

sub swapping-makes-the-piece-belong-to-horizontal-instead {
    ok 0, "swapping makes the piece belong to horizontal instead";
}

sub swapping-is-allowed-as-the-second-move {
    ok 0, "swapping is allowed as the second move";
}

sub swapping-is-not-allowed-as-the-first-move {
    ok 0, "swapping is not allowed as the first move";
}

sub swapping-is-not-allowed-after-the-second-move {
    ok 0, "swapping is not allowed after the second move";
}

sub passing-does-not-change-the-board {
    ok 0, "passing does not change the board";
}

sub passing-makes-it-the-other-player's-turn {
    ok 0, "passing makes it the other player's turn";
}

sub resigning-does-not-change-the-board {
    ok 0, "resigning does not change the board";
}

sub resigning-ends-the-game {
    ok 0, "resigning ends the game";
}

sub a-chain-wins-the-game-if-it-connects-a-player's-edges {
    ok 0, "a chain wins the game if it connects a player's edges";
}

sub a-chain-does-not-win-the-game-if-it-connects-the-enemy's-edges {
    ok 0, "a chain does not win the game if it connects the enemy's edges";
}

# vim: filetype=perl6
