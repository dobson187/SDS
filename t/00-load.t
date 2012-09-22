#!perl -T

use Test::More tests => 8;

BEGIN {
    use_ok( 'SDS' ) || print "Bail out!\n";
    use_ok( 'SDS::Index' ) || print "Bail out!\n";
    use_ok( 'SDS::Genome' ) || print "Bail out!\n";
    use_ok( 'SDS::SamToBed' ) || print "Bail out!\n";
    use_ok( 'SDS::Algorithm' ) || print "Bail out!\n";
    use_ok( 'SDS::Enrichment' ) || print "Bail out!\n";
    use_ok( 'SDS::Enrichment::Peaks' ) || print "Bail out!\n";
    use_ok( 'SDS::WigEncode' ) || print "Bail out!\n";
}

diag( "Testing SDS $SDS::VERSION, Perl $], $^X" );
