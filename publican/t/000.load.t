use strict;
use warnings;

use Test::More tests => 1;
use File::Path;

BEGIN {
use_ok( 'Publican' );
}

diag( "Testing Publican $Publican::VERSION" );

rmtree( [ 'foo', 'foo2', 'Test_Book', 'Test_Article', 'Test_Set', 'User_Guide/tmp'] );
#my $publican = Publican->new();
#isa_ok($publican, 'Publican', 'creating a Publican');

