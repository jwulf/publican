use strict;
use warnings;

use Test::More tests => 5;
use File::pushd;
use Cwd qw(abs_path);

BEGIN {
    use_ok('Publican');
    use_ok('Publican::Builder::DocBook5');
}

my $dir = pushd("Test_DB5_Book");

my $publican = Publican->new(
    {
        debug          => 1,
        NOCOLOURS      => 1,
        QUIET          => 1,
    }
);

my $builder = Publican::Builder::DocBook5->new();
isa_ok( $builder, 'Publican::Builder::DocBook5', 'creating a Publican::Builder::DocBook5' );

eval { $builder->build( { formats => "html,pdf", langs => "en-US", pub_dir => 'publishing' } ) };
my $e = $@;
ok( ( not $e ), "build a DB5 book" );
diag($e) if $e;

eval { $builder->package( { lang => "en-US" } ) };
$e = $@;
ok( ( not $e ), "package a DB5 book" );
diag($e) if $e;

$dir = undef;

