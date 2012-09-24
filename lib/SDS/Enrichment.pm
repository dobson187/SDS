package SDS::Enrichment;

use Moose;
use File::Temp;
use Data::Dumper;
use SDS::SamToBed;
use File::Copy;

# The following section contains the Moose declarations for construction

has input_bed	=>	(
	is				=>	'ro',
	isa				=>	'File::Temp',
	required		=>	1,
);

has ip_bed	=>	(
	is				=>	'ro',
	isa				=>	'File::Temp',
	required		=>	1,
);

has index_file	=>	(
	is				=>	'ro',
	isa				=>	'File::Temp',
	required		=>	1,
);

has executor	=>	(
	is				=>	'ro',
	isa				=>	'SDS::SamToBed',
	required		=>	1,
	default			=>	sub {
		my $self = shift;
		my $sam_to_bed = SDS::SamToBed->new(
			sam_file	=>	'none',
		);
		return $sam_to_bed;
	},
);

has enrichment_interval	=>	(
	is				=>	'ro',
	isa				=>	'Int',
	required		=>	1,
);

has sequence_depth_scaling_factor	=>	(
	is				=>	'ro',
	isa				=>	'Num',
	required		=>	1,
);

has chromosome_sizes	=>	(
	is				=>	'ro',
	isa				=>	'HashRef[Int]',
	required		=>	1,
);



# The calculate_enrichment_estimates is the main subroutine called by the
# SDS.pm controller module. This subroutine will scale the input reads,
# then for each non-overlapping interval of enrichment_interval size, this
# subroutine will calculate the ratio of IP tag density to input tag
# density. This subroutine will return a File::Temp object containing a
# reference to the Wiggle file of enrichment estimates.

sub calculate_enrichment_estimates {
	my $self = shift;
	# Make calls to the _intersect_bed subroutine for both the IP and input
	# tag channels to intersect the BED files with the enrichment_interval
	# length genomic intervals BED file to determine the number of reads
	# per interval.
	my $input_reads_per_enrichment_estimate =
	$self->_intersect_bed($self->input_bed);
	my $ip_reads_per_enrichment_estimate =
	$self->_intersect_bed($self->ip_bed);
	# Create a temporary file structure
	my $temp_file_structure = $self->_temp_file_structure;
	# Make calls to the _separate_reads_by_chromosome subroutine for both
	# the IP and input tag channels to write the reads for each file for
	# each chromosome to a separate temporary file.
	$self->_separate_reads_by_chromosome($input_reads_per_enrichment_estimate,
		'Input', $temp_file_structure
	);
	$self->_separate_reads_by_chromosome($ip_reads_per_enrichment_estimate,
		'IP', $temp_file_structure
	);
	# Pre-declare an Array Ref to hold the genome-wide wiggle data
	my $wiggle_file = [];
	# Iterate through the chromosomes in the genome, extracting the wiggle
	# format data for each channel and calculating the normalized relative
	# enrichment.
	foreach my $chromosome ( keys %$temp_file_structure ) {
		# Read in the contents of the wiggle files for both the IP and
		# input channels
		my $ip_wiggle_file =
		$temp_file_structure->{$chromosome}{IP};
		my @ip_wiggle = <$ip_wiggle_file>;
		chomp(@ip_wiggle);
		my $input_wiggle_file =
		$temp_file_structure->{$chromosome}{Input};
		my @input_wiggle = <$input_wiggle_file>;
		chomp(@input_wiggle);
		# Push the header line for this chromosome onto the genome-wide
		# wiggle file
		push (@$wiggle_file, $ip_wiggle[0]);
		# Iterate through the rest of the lines in each file, calculating
		# the normalized enrichment estimate at each interval.
		for ( my $i = 1; $i < @ip_wiggle; $i++ ) {
			$input_wiggle[$i] *= $self->sequence_depth_scaling_factor;
			if ( $input_wiggle[$i] == 0 ) {
				$input_wiggle[$i] = $self->sequence_depth_scaling_factor;
			}
			push (@$wiggle_file, ($ip_wiggle[$i] / $input_wiggle[$i]));
		}
	}
	# Create a File::Temp object to print the genome-wide Wiggle data to.
	# Then return the File::Temp object to the main SDS.pm controller
	# subroutine.
	my $temp_wiggle_file = File::Temp->new(
		SUFFIX	=>	'_Genome-wide_Enrichment_Estimates.wig',
	);
	open my $wig_out, ">", $temp_wiggle_file or die "Could not write to the " . $temp_wiggle_file . " temporary file. Please make sure you have permission to write to the temp directory $! \n";
	print $wig_out join("\n", @$wiggle_file);
	copy($temp_wiggle_file, '/home/jason/test.wiggle');
	return $temp_wiggle_file;
}

# The private _intersect_bed subroutine is used to create a temporary BED
# format file indicating the number of reads per enrichment_interval length
# genomic coordinates.

sub _intersect_bed {
	my ($self, $reads_file) = @_;
	# Create a File::Temp object to hold the output of the intersectBed
	# call
	my $reads_per_enrichment_interval = File::Temp->new(
		SUFFIX	=>	'_reads_per_enrichment_interval.wig'
	);
	my $intersect_bed_command = 'intersectBed -c -a ' . $self->index_file .
	' -b ' . $reads_file . ' > ' . $reads_per_enrichment_interval;
	$self->executor->run_command($intersect_bed_command);
	return $reads_per_enrichment_interval;
}

# The _temp_file_structure private subroutine is used to create an index of
# File::Temp objects to which the wiggle data for each chromosome will be
# written.

sub _temp_file_structure {
	my $self = shift;
	# Pre-declare a Hash Ref to store the tree of File::Temp objects
	my $temp_files = {};
	foreach my $chromosome ( keys %{$self->chromosome_sizes} ) {
		$temp_files->{$chromosome}{Input} = File::Temp->new(
			SUFFIX	=>	'_' . $chromosome . '_Input_Temp.bed',
		);
		$temp_files->{$chromosome}{IP} = File::Temp->new(
			SUFFIX	=>	'_' . $chromosome . '_IP_Temp.bed',
		);
	}
	return $temp_files;
}

# The _separate_reads_by_chromosome private subroutine is used by the main
# subroutine, and is passed a File::Temp object corresponding to the reads
# per enrichment_interval and a string indicating the channel for the
# reads. This subroutine then parses the reads by chromosome, and writes
# the reads per chromosome to file in Wiggle format.

sub _separate_reads_by_chromosome {
	my ($self, $reads_file, $channel, $temp_file_structure) = @_;
	# Pre-declare an Array Ref to hold the wiggle file data
	my $wiggle_file = [];
	# Pre-declare a string for the name of the chromosome
	my $current_chromosome = '';
	while (<$reads_file>) {
		my $line = $_;
		chomp($line);
		my ($chr, $start, $stop, $reads) = split(/\t/, $line);
		if ( ! $current_chromosome ) {
			push(@$wiggle_file, "fixedStep chrom=$chr start=1 step=" .
				$self->enrichment_interval . " span=" .
				$self->enrichment_interval
			);
			$current_chromosome = $chr;
			push(@$wiggle_file, $reads);
		} elsif ( $current_chromosome eq $chr ) {
			push (@$wiggle_file, $reads);
		} elsif ( $chr ne $current_chromosome ) {
			open my $out_fh, ">",
			$self->_temp_file_structure->{$current_chromosome}{$channel} or
			die "Could not write to temporary file " .
			$temp_file_structure->{$current_chromosome}{$channel} .
			" used to make wiggle files for each chromosome. Please check that you have permissions to write to the temp folder. $! \n";
			print $out_fh join("\n", @$wiggle_file);
			$wiggle_file = [];
			$current_chromosome = $chr;
			push(@$wiggle_file, "fixedStep chrom=$chr start=1 step=" .
				$self->enrichment_interval . " span=" .
				$self->enrichment_interval
			);
			push(@$wiggle_file, $reads);
		}
	}
	open my $out_fh, ">",
	$temp_file_structure->{$current_chromosome}{$channel} or
	die "Could not write to temporary file " .
	$self->_temp_file_structure->{$current_chromosome}{$channel} .
	" used to make wiggle files for each chromosome. Please check that you have permissions to write to the temp folder. $! \n";
	print $out_fh join("\n", @$wiggle_file);
}

1;

__END__

=head1 NAME

SDS::Enrichment

=head1 SYNOPSIS



=head1 AUTHOR

Jason R Dobson, C<< <dobson187 at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sds at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SDS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SDS::Enrichment


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


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Jason R Dobson.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
