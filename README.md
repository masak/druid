Druid is a connection-oriented board game created by Cameron Browne.

This is how a typical board might look:

          A     B     C     D     E
       +-----+-----+-----+-----+-----+
     5 |                             | 5
       |+-----+           +-----+    |
       /| h h |    +     /| v v |    +
     4 || h h |          || v v |    | 4
       |+-----+-----+    |+-----+    |
       /-----/| v v |    /-----/     +
     3 |     || v v |                | 3
       |     |+-----+     +-----+    |
       +     /-----/     /| v v |    +
     2 |             +-----+-----+-----+
       |      +-----/| h h   h h   h h |
       +     /| v v || h h   h h   h h |
     1 |     || v v |+-----+-----+-----+
       |     |+-----/-----/-----/-----/
       +-----/-----/-----/-----/-----/
          A     B     C     D     E

Rules and a bit of strategy can be found at
http://www.cameronius.com/games/druid/

Instructions on getting Druid running:

* Get Rakudo Star or install Rakudo and Panda manually.
* Call 'panda install druid'.

## Get Rakudo

You need Rakudo to run the Perl 6 code in Druid -- instructions
here: <http://rakudo.org/how-to-get-rakudo/>.

## Call 'perl6 druid'

Yup, you're ready to go.

    % perl6 -Ilib bin/druid
    % perl6 -Ilib bin/druid --size=10 --computer=1
    % perl6 -Ilib bin/druid --help

## For those who want to compile things

(After all, compilation does make startup a little faster.)

Install ufo with panda or get it from github. Then run

    % ufo
    % make

## Installing via panda

Panda is a no-fuss installer of Perl 6 projects. You have it already if you
have installed the Rakudo Star distribution, but otherwike you can install
it like so:

1. Get panda from <https://github.com/tadzik/panda>
2. Run './bootstrap' and make sure to set your PATH as it instructs you to.
3. Run 'panda install druid'

...and you're ready to run. Just run "druid" in your shell.

## Future plans

* Add an SVG renderer.

* Work on the machine play. (It's currently random, but I have some fairly
  nice ideas lying around in a local branch.)

* Put in a few optimizations to make Druid::Game::possible-moves O(1)
  instad of O($n**2) ($n being the size of the board), as it is presently.
  In another language, the difference might not actually be noticeable, but
  Rakudo Perl 6 is very "speed-sensitive" right now.

* Make the web app do POST requests instead of GET requests. This is more in
  line with the idea of making a move, a non-idempotent action.

* Make the web app handle different simultaneous games, played by distinct
  users. This will likely require a real databse instead of the short-term
  file solution used now.

## License

This Druid implementation is released under Artistic 2.0. See LICENSE.
Permission to release the game graciously given by the game author.
