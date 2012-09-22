#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: sequenceDepthScalingPeaks.pl
#
#        USAGE: ./sequenceDepthScalingPeaks.pl  
#
#  DESCRIPTION: This script executes the sequence depth scaling (SDS)
#  				algorithm (SDS), which has been implemented in Perl.
#
#      OPTIONS: ---
# REQUIREMENTS: External Binaries: SAMTools, BEDTools, MySQL
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Jason R. Dobson (JRD), dobson187@gmail.com
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 09/22/2012 03:05:39 PM
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use SDS;

my $sds = SDS->new_with_options();
$sds->execute;
