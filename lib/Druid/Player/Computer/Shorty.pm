use v6;
use Druid::Player::Computer;

class Druid::Player::Computer::Shorty is Druid::Player::Computer {
    method choose_move() {
        my %h = {
            'north edge' => <a3 b3 c3>,
            'south edge' => <a1 b1 c1>,
        };
        for <a b c> Z <? a b> Z <b c ?> -> $col, $col_left, $col_right {
            for 1..3 Z 0..2 Z 2..4 -> $row, $row_below, $row_above {
                my @neighbors =
                    $row_below == 0 ?? 'south edge' !! $col ~ $row_below,
                    $row_above == 4 ?? 'north edge' !! $col ~ $row_above,
                    $col_left  eq '?' ?? () !! $col_left  ~ $row,
                    $col_right eq '?' ?? () !! $col_right ~ $row;
                %h{$col~$row} = @neighbors;
            }
        }
        for %h.keys -> $node {
            next if $node ~~ /edge/;
            $node ~~ $.sarsen_move;
            my $row    = $<coords><row_number> - 1;
            my $column = ord($<coords><col_letter>) - ord('a');
            # TODO: Generalize 1
            if @.colors[$row][$column] == 1 {
                my @neighbors = %h{$node}.values;
                for %h{$node}.values -> $neighbor {
                    next unless %h.exists($neighbor);
                    %h{$neighbor}.push(grep { $_ ne $neighbor }, @neighbors);
                    my %uniq = map { ($_ => 1) }, %h{$neighbor}.values;
                    %h{$neighbor} = %uniq.keys;
                }
                %h.delete($node);
            }
        }
        for %h.kv <-> $node, $neighbors {
            $neighbors = grep { %h.exists($_) }, $neighbors.values;
        }
        my @queue = 'north edge';
        my %distances = map { ($_ => Inf) }, %h.keys;
        %distances{'north edge'} = 0;
        my %paths;
        %paths{'north edge'} = [];
        my %visited;
        while @queue {
            my $node = shift @queue;
            for %h{$node}.values -> $neighbor {
                %distances{$neighbor}
                    = %distances{$neighbor} min %distances{$node} + 1;
                if !%visited{$neighbor} {
                    push @queue, $neighbor;
                }
                if !%paths.exists($neighbor) {
                    %paths{$neighbor} = [%paths{$node}.values, $node];
                }
            }
            %visited{$node}++;
        }
        my @path = %paths{'south edge'}.values;
        shift @path;
        return @path[0];
    }
}
