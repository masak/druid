use v6;

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
