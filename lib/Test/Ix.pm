use v6;
use Test;

# This module takes a recursive list of tests and autogenerates test subs
# from it, injecting those subroutines into a given file. It also handles
# traversing the same list in order to count or run the tests in a file.

sub inject-subs-in-file($file) {
    my $code = slurp($file)
        or die "Couldn't open $file";
    $code ~~ /'my ' ('@tests =' <-[;]>+ ';')/
        or die "Couldn't find declaration.";
    my $declaration = ~$0;
    my @tests = find-all-tests-in-declaration($declaration);
    for @tests -> $test {
        my $subname = $test.subst(' ', '-', :global);
        next if $code ~~ /'my &*' $subname/; # already in there
        my $sub =
            sprintf (join "\n", 'my &*%s = sub {', '    ok 0, "%s";', '}', ''),
                                     $subname,          $test;
        $code = inject $sub, :into($code);
    }
    return $code;
}

sub find-all-tests-in-declaration($declaration) {
    my @tests;
    EVAL($declaration); # see what's going on here? :) aye, evil eval, I know.

    return find-all-tests(@tests)
}

sub find-all-tests(@tests) {
    return traverse-tests(@tests, { take $_ });
}

multi sub traverse-tests(@tests, Code $leaf-action) {
    return gather { traverse-tests(@tests, $leaf-action, '') };
}

multi sub traverse-tests(@tests, Code $leaf-action, $prefix) {
    for @tests -> $test {
        if $test ~~ Pair {
            traverse-tests($test.value,
                           $leaf-action,
                           sprintf('%s%s ', $prefix, $test.key));
        }
        elsif $test ~~ Str {
            try {
                $leaf-action($prefix ~ $test);
                CATCH {
                    default {
                        ok 0, "{$prefix.trim-trailing}/$test";
                        note $_;
                    }
                }
            }
        }
        else {
            die "Don't understand a {$test.WHAT} in the declaration.";
        }
    }
}

sub inject(Str $sub, Str :into($code)!) {
    my @lines = $code.split("\n");
    my $line-with-vim-conf = first-index { $_ ~~ /^ '# vim'/ }, @lines;
    # RAKUDO: $line-with-vim-conf ~~ Nil [perl #63894]
    if $line-with-vim-conf.WHAT ne 'Nil' {
        return join "\n", @lines[0 ..^ $line-with-vim-conf],
                          $sub,
                          @lines[$line-with-vim-conf ..^ *];
    }
    return $code ~ $sub;
}

sub first-index(Code $cond, @array) {
    for @array.kv -> $index, $elem {
        return $index if $cond($elem);
    }
    return ();
}

sub count-tests(@tests) is export {
    return +traverse-tests(@tests, { take $_ });
}

sub run-tests(@tests) is export {
    my \PKG := CALLER::;
    my &runtest = {
        my $subname = $_.subst(' ', '-', :global);
        my $sub = PKG{'&*'~$subname};
        if $sub ~~ :!defined {
            ok 0, sprintf 'tried to run %s but it did not exist', $subname;
        } else {
            my @arguments = PKG{'&*before'} ~~ Sub # is there a &before sub?
                                ?? PKG{'&*before'}().list[ 0 ..^ $sub.arity ]
                                !! Any xx $sub.arity;
            $sub(|@arguments);
            PKG{'&*after'} ~~ Sub
                and PKG{'&*after'}();
        }
    };
    traverse-tests(@tests, &runtest);
}
