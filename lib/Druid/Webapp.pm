use v6;
use Tags; 
use Druid::Game; 
use Druid::View::Text;

class Druid::Webapp {

    method page(Str $query-string) {
        my $board-size = 8;
        my Druid::Game $game .= new(:size($board-size));
        my Druid::View $view = Druid::View::Text.new(:$game);

        return
            show {
                html {
                    head { title { 'Druid' } }
                    body {
                        pre { $view }
                        object :type<image/svg+xml>, :data</board.svg>, {
                            'alternate text'
                        }
                        ul {
                            for $game.possible-moves() -> $move {
                                li {
                                    a :href("?moves=$move"), { $move }
            }}}}}};
    }

}
