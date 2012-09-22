package SDS;

use Moose;
use lib "$FindBin::Bin/../lib";
use SDS::Algorithm;
use SDS::Enrichment;
use SDS::Enrichment::Peaks;
use SDS::Genome;
use SDS::Index;
use SDS::SamToBed;
use SDS::WigEncode;
use Pod::Usage;

with 'MooseX::Getopt';

1;

__END__

=head1 NAME

SDS - The sequence depth scaling algorithm implemented in Perl.

=head1 SYNOPSIS

This module is designed to be used as the 'Controller' between the script
'SDS/bin/sequenceDepthScalingPeaks.pl' and the business logic found un the
sub-tree modules of SDS.

sequenceDepthScalingPeaks.pl {OPTIONS} --genome --input [PATH TO INPUT FILE] 
--ip [PATH TO IP FILE] 

Example usage:

sequenceDepthScalingPeaks \
	--genome hg19 \
	--input input.sam \
	--ip PolII.sam \
	--name hES_PolII

Options:

	--genome		The abbreviation for the genome the reads are mapped
					to. e.g. hg19 or mm9.
	--input			File path to the SAM-format mapped input reads.
	--ip			File path to the SAM-format mapped ip reads.
	--sds_interval		Integer value for the size (bp) of the intervals 
						used to partition the genome for the sequence depth 
						scaling algorithm. Default = 1000.
	--enrichment_interval		Integer value for the size (bp) of the
								intervals used to calculate the enrichment
								of IP to input DNA. Default = 10.
	--peak_size			Integer value for the minimum considred peak-width
						used when determining the BED-format coordinates of
						enriched regions. Value specified must be divisible 
						by the --enrichment_interval. Default = 200.
	--name				String specifying the name of the experiment.
						Default = 'SDS_Experiment'.

=head1 OPTIONS

=over 8

=item B<--help>

Print a brief help message and then exit.

=item B<--usage>

Print a brief help message and then exit.

=item B<?>

Print a brief help message and then exit.

=item B<--man>

Display the full manual in POD format for SDS.

=item B<--genome>

The abbreviation for the genome to which the reads for the samples are
mapped.

=item B<--input>

The file path to the SAM-format mapped input reads.

=item B<--ip>

The file path to the SAM-format mapped IP reads.

=item B<--sds_interval>

Integer value for the size (in bp) for the interval windows used to
calculate the sequence scaling factor in the sequence depth scaling
algorithm. Default = 1000.

=item B<--enrichment_interval>

Integer value for the size (in bp) for the interval windows used to
calculate the relative enrichment of the IP read density relative to the
input read density. Default = 10.

=item B<--peak_size>

Integer value for the size (in bp) set as the minimum length considered
when searching for enriched genomic coordinates. Value set must be
divisible by the --enrichment_interval value. Default = 200.

=item B<--name>

String specifying the name of the experiment. Default = 'SDS_Experiment'.

=back

=head1 AUTHOR

Jason R Dobson, C<< <dobson187 at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sds at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SDS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SDS


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SDS>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SDS>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SDS>

=item * Search CPAN

L<http://search.cpan.org/dist/SDS/>

=back


=head1 ACKNOWLEDGEMENTS

SDS Algorithm:

Diaz, A., Park, K., Lim, D. A., & Song, J. S. (2012). Normalization, bias
correction, and peak calling for ChIP-seq. Statistical applications in
genetics and molecular biology, 11(3), Article 9.
doi:10.1515/1544-6115.1750

BEDTools:

Quinlan, A. R., & Hall, I. M. (2010). BEDTools: a flexible suite of
utilities for comparing genomic features. Bioinformatics, 26(6), 841–842.
doi:10.1093/bioinformatics/btq033

SAMTools

Li, H., Handsaker, B., Wysoker, A., Fennell, T., Ruan, J., Homer, N.,
Marth, G., et al. (2009). The Sequence Alignment/Map format and SAMtools.
Bioinformatics, 25(16), 2078–2079. doi:10.1093/bioinformatics/btp352

UCSC Genome Browser Interactions and Chromosome Definitions

Fujita, P. A., Rhead, B., Zweig, A. S., Hinrichs, A. S., Karolchik, D.,
Cline, M. S., Goldman, M., et al. (2011). The UCSC Genome Browser database:
update 2011. Nucleic Acids Research, 39(Database issue), D876–82.
doi:10.1093/nar/gkq963

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Jason R Dobson.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

