use strict;
use warnings;

use Test::More tests => 10;

BEGIN {
    use_ok('Publican');
    use_ok('Publican::CreateBook');
}

my $creator = Publican::CreateBook->new( { name => 'Test_Book' } );
isa_ok( $creator, 'Publican::CreateBook', 'creating a Publican::CreateBook' );

eval { $creator->create() };
my $e = $@;
ok( ( not $e ), "create a book" );
diag($e) if $e;

$creator = Publican::CreateBook->new(
    { name => 'Test_Article', type => 'Article' } );
isa_ok( $creator, 'Publican::CreateBook', 'creating a Publican::CreateBook' );

eval { $creator->create() };
$e = $@;
ok( ( not $e ), "create an article" );
diag($e) if $e;

$creator = Publican::CreateBook->new( { name => 'Test_Set', type => 'Set' } );
isa_ok( $creator, 'Publican::CreateBook', 'creating a Publican::CreateBook' );

eval { $creator->create() };
$e = $@;
ok( ( not $e ), "create a set" );
diag($e) if $e;
$creator = undef;

my $creator2 = Publican::CreateBook->new( { name => 'Test_DB5_Book', dtdver => '5.0' } );
isa_ok( $creator2, 'Publican::CreateBook', 'creating a Publican::CreateBook' );

eval { $creator2->create() };
$e = $@;
ok( ( not $e ), "create a DB5 book" );
diag($e) if $e;

