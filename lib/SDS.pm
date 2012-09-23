package SDS;

use Moose;
use FindBin;
use lib "$FindBin::Bin/../lib";
use SDS::Algorithm;
use SDS::Enrichment;
use SDS::Enrichment::Peaks;
use SDS::Genome;
use SDS::Index;
use SDS::SamToBed;
use SDS::WigEncode;
use Pod::Usage;
use Data::Dumper;

with 'MooseX::Getopt';

# Define the Moose options accepted at the command-line

has man	=>	(
	is				=>	'ro',
	isa				=>	'Bool',
	documentation	=>	"Flag which displays the POD for this program.",
);

has genome	=>	(
	is				=>	'ro',
	isa				=>	'Str',
	required		=>	1,
	lazy			=>	1,
	documentation	=>	"String abbreviation of the genome to which the reads were mapped to. For example: hg19 or mm9.",
	default			=>	sub { pod2usage(
			-message	=>	"\n\nYou must define a genome.\n\n",
			-verbose	=>	1,
			-exitval	=>	2,
			-input		=>	"$FindBin::Bin/../lib/SDS.pm",
		);
	},
);

has input	=>	(
	is				=>	'ro',
	isa				=>	'Str',
	required		=>	1,
	lazy			=>	1,
	documentation	=>	"The file path to the input file in SAM format.",
	default			=>	sub { pod2usage(
			-message	=>	"\n\nYou must define an input file.\n\n",
			-verbose	=>	1,
			-exitval	=>	2,
			-input		=>	"$FindBin::Bin/../lib/SDS.pm",
		);
	},
);

has ip	=>	(
	is				=>	'ro',
	isa				=>	'Str',
	required		=>	1,
	lazy			=>	1,
	documentation	=>	"The file path to the IP file in SAM format.",
	default			=>	sub { pod2usage(
			-message	=>	"\n\nYou must define an IP file.\n\n",
			-verbose	=>	1,
			-exitval	=>	2,
			-input		=>	"$FindBin::Bin/../lib/SDS.pm",
		);
	},
);

has name	=>	(
	is				=>	'ro',
	isa				=>	'Str',
	documentation	=>	"A string defining the name of the experiment. Default: 'SDS_Experiment'.",
	default			=>	'SDS_Experiment',
);

has sds_interval	=>	(
	is				=>	'ro',
	isa				=>	'Int',
	required		=>	1,
	documentation	=>	"Integer value setting the size (bp) of the intervals used to calculate the sequence scaling factor. Default = 1000.",
	default			=>	1000,
);

has enrichment_interval	=>	(
	is				=>	'ro',
	isa				=>	'Int',
	required		=>	1,
	documentation	=>	"Integer value setting the size (bp) of the intervals used to calculate the relative enrichment of the IP reads over the input reads. Default = 10.",
	default			=>	10,
);

has peak_size	=>	(
	is				=>	'ro',
	isa				=>	'Int',
	required		=>	1,
	documentation	=>	"Integer value setting the size (bp) of the intervals used to define the minimum width of a peak when determining coordinates of enriched regions. Value set must be divisible by the enrichment_interval. Default = 200.",
	default			=>	200,
);

sub execute {
	my $self = shift;
	# Check to see whether the user has flagged to see the manual
	if ( $self->man ) {
		pod2usage(
			-verbose	=>	2,
			-exitval	=>	1,
			-input		=>	"$FindBin::Bin/../lib/SDS.pm",
		);
	}
	# Check that the peak_size is valid based on the enrichment_interval
	$self->_valid_peak_size;
	# Create a data structure to hold the file paths defined by the user as
	# well as the File::Temp objects created to hold the intermediate files
	# created by SDS
	my $sds_structure = {};
	$sds_structure->{'SAM Files'}{Input} = $self->input;
	$sds_structure->{'SAM Files'}{IP} = $self->ip;
	# Construct an instance of SDS::Genome in order to fetch the chromosome
	# sizes from the UCSC MySQL server
	my $genome = SDS::Genome->new(
		genome	=>	$self->genome,
	);
	my ($chromosome_sizes, $chromosome_sizes_fh) =
	$genome->chromosome_sizes;
	# For the input and IP files, create an instance of SDS::SamToBed and
	# convert the files to BED-format files. The File::Temp objects
	# corresponding to the final BED-format files will be stored in the SDS
	# structure.
	foreach my $file_type ( keys %{$sds_structure->{'SAM Files'}} ) {
		my $sam_to_bed = SDS::SamToBed->new(
			sam_file				=>	$sds_structure->{'SAM Files'}{$file_type},
		);
		$sds_structure->{'BED Files'}{$file_type} = $sam_to_bed->convert;
	}
	# Now that the BED format files have been created for the input and IP
	# reads, now it is time to calculate the sequence scaling factor. First
	# a non-overlapping index of length sds_interval for the user-defined
	# genome must be defined.
	#
	# Create an SDS::Index object
	my $index_creator = SDS::Index->new(
		chromosome_sizes	=>	$chromosome_sizes,
		sds_interval		=>	$self->sds_interval,
	);
	# Execute the create_index subroutine from SDS::Index, which will
	# return a File::Temp object containing the temporary index file.
	my $sds_index_fh = $index_creator->create_index;
}

# The following is a private subroutine used to determine whether the
# user-defined peak_size is valid
sub _valid_peak_size {
	my $self = shift;
	if ( $self->peak_size % $self->enrichment_interval ) {
		pod2usage(
				-message	=>	"\n\nYou must define a peak_size, which is evenly divisible by the enrichment_interval.\n\n",
				-verbose	=>	1,
				-exitval	=>	2,
				-input		=>	"$FindBin::Bin/../lib/SDS.pm",
		);
	}
} # end _valid_peak_size

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

SDS - The sequence depth scaling algorithm implemented in Perl.

=head1 DESCRIPTION

This module is designed to be used as the 'Controller' between the script
'SDS/bin/sequenceDepthScalingPeaks.pl' and the business logic found un the
sub-tree modules of SDS.

=head1 SYNOPSIS

sequenceDepthScalingPeaks.pl {OPTIONS} --genome --input [PATH TO INPUT FILE] 
--ip [PATH TO IP FILE] 

Example usage:

sequenceDepthScalingPeaks --genome hg19 --input input.sam --ip PolII.sam --name hES_PolII

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

