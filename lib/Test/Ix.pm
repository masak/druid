use v6;
use Test;

sub inject-subs-in-file($file) {
    my $code = slurp($file)
        or die "Couldn't open $file";
    $code ~~ /'my ' ('@tests =' <-[;]>+ ';')/
        or die "Couldn't find declaration.";
    my $declaration = ~$0;
    my @tests = find-all-tests-in-declaration($declaration);
    for @tests -> $test {
        my $subname = $test.subst(' ', '-', :global);
        # RAKUDO: Can't interpolate strings in regexes [perl #63892]
        #next if $code ~~ /'sub ' $subname/; # already in there
        my $subname-escaped = $subname.subst("'", "\\'", :global);
        next if $code ~~ eval("/'$subname-escaped'/"); # already in there
        my $sub =
            sprintf (join "\n", 'sub %s {', '    ok 0, "%s";', '}', ''),
                                     $subname,          $test;
        $code = inject($sub, :into($code));
    }
    return $code;
}

sub find-all-tests-in-declaration($declaration) {
    my @tests;
    eval($declaration); # see what's going on here? :) aye, evil eval, I know.

    return find-all-tests(@tests)
}

multi sub find-all-tests(@tests) {
    return gather { find-all-tests(@tests, '') }
}

multi sub find-all-tests(@tests, $prefix) {
    for @tests -> $test {
        if $test ~~ Pair {
            find-all-tests($test.value, sprintf('%s%s ', $prefix, $test.key));
        }
        elsif $test ~~ Str {
            take $prefix ~ $test;
        }
        else {
            die "Don't understand a {$test.WHAT} in the declaration.";
        }
    }
}

# RAKUDO: Would like to make this a named param. [perl #63230]
# sub inject(Str $sub, Str :into($code)!) {
sub inject(Str $sub, Str :$into!) {
    my @lines = $into.split("\n");
    my $line-with-vim-conf = first-index { $_ ~~ /^ '# vim'/ }, @lines;
    # RAKUDO: $line-with-vim-conf ~~ Nil [perl #63894]
    if $line-with-vim-conf.WHAT ne 'Nil' {
        return join "\n", @lines[0 ..^ $line-with-vim-conf],
                          $sub,
                          @lines[$line-with-vim-conf ..^ *];
    }
    return $into ~ $sub;
}

sub first-index(Code $cond, @array) {
    for @array.kv -> $index, $elem {
        return $index if $cond($elem);
    }
    return ();
}

multi sub count-tests(@tests) {
    my Int $total;
    for @tests -> $test {
        if $test ~~ Pair {
            $total += count-tests($test.value);
        }
        elsif $test ~~ Str {
            ++$total;
        }
        else {
            die "Don't understand a {$test.WHAT} in the declaration.";
        }
    }
    return $total;
}

multi sub run-tests(@tests) {
    for @tests -> $test {
        if $test ~~ Pair {
            run-tests($test.value);
        }
        elsif $test ~~ Str {
            my $subname = $test.subst(' ', '-', :global);
            eval($subname);
            if $! {
                ok 0, sprintf 'tried to run %s but it did not exist', $subname;
            }
        }
        else {
            die "Don't understand a {$test.WHAT} in the declaration.";
        }
    }
}
