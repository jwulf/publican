use utf8;
use strict;
use warnings;

use Test::More tests => 4;
use File::pushd;
use Cwd qw(abs_path);

BEGIN {
    use_ok('Publican');
    use_ok('Publican::Translate');

    #use_ok( 'Publican::Builder' );
}

#my $dir = pushd("Users_Guide");
my $dir = pushd("Test_Book");

my $publican = Publican->new(
    {   debug          => 1,
        NOCOLOURS      => 1,

    }
);

my $trans = Publican::Translate->new();

eval { $trans->update_pot() };
my $e = $@;
ok( ( not $e ), "Update POT  files" );
diag($e) if $e;

#my $builder = Publican::Builder->new();

#eval { $builder->build({formats => "html-single", langs => "de-DE"}) };
#$e = $@;
#ok( (not $e),  "build a book" );
#diag($e) if $e;

# Basic regression test for BZ #1233202
my $nbsp_string = "\x{00a0}(more than 5\x{00a0}MB for the largest <filename>Packages.gz</filename>\x{00a0}";
eval { $e = Publican::Translate::detag( "<para>${nbsp_string}</para>", "para" ) };
is( $e, $nbsp_string, 'BZ #1233202 Regression test' );

$dir = undef;