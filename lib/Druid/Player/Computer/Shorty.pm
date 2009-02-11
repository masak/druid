use v6;
use Druid::Player::Computer;

class Druid::Player::Computer::Shorty is Druid::Player::Computer {
    method choose_move() {
        return 'b2';
    }
}
