package SDS::Algorithm;

use Moose;
use File::Temp;
use SDS::SamToBed;
use Data::Dumper;

# This section is for Moose constructor declarations

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

# The calculate_scaling_factor subroutine is the main subroutine called by
# the controller SDS.pm module. It will execute the SDS algorithm and
# return to SDS.pm a floating point number corresponding to the
# multiplicative scaling factor used to scale the input read density.

sub calculate_scaling_factor {
	my $self = shift;
	# Calculate the number of reads in both the input and IP channel using
	# the _count_reads private subroutine
	my $input_reads = $self->_count_reads($self->input_bed);
	my $ip_reads = $self->_count_reads($self->ip_bed);
	# Calculate the number of reads per SDS interval for the input and
	# Input respectively. To do this, use the _reads_per_interval private
	# subroutine.
	my ($input_reads_per_interval, $ip_reads_per_interval,
		$ordered_intervals) =
	$self->_reads_per_interval;
	# The following is the implementation of the SDS algorithm using the
	# sorted statistic from the IP channel.
	#
	# Iterate through the ordered intervals using the interval as the key 
	# to access the number of reads found in the interval. Calculate the 
	# partial sum of the number of reads for each interval, and determine 
	# the cumulative percent of reads for input and IP channels. Store the
	# difference between the cumulative percentages and the bin number in a
	# Hash Ref, which will be dynamically updated when the difference is
	# larger. This will effectively calculate the bin at which the reads 
	# in the input channel maximally exceeds the reads in the IP channel. 
	my $aggregate_ip_reads = 0;
	my $aggregate_input_reads = 0;
	my $maximum_bin_and_percentage_difference = {
		bin			=>	0,
		difference	=>	0,
	};
	my $bin = 1;
	foreach my $ordered_interval (@$ordered_intervals) {
		$aggregate_ip_reads += $ip_reads_per_interval->{$ordered_interval};
		$aggregate_input_reads += 
		$input_reads_per_interval->{$ordered_interval};
		my $percentage_difference = (
			(( $aggregate_input_reads / $input_reads ) * 100) - 
			(( $aggregate_ip_reads / $ip_reads) * 100 )
		);
		if ( $percentage_difference >
			$maximum_bin_and_percentage_difference->{difference} ) {
			$maximum_bin_and_percentage_difference->{difference} =
			$percentage_difference;
			$maximum_bin_and_percentage_difference->{bin} = $bin;
		}
		$bin++;
	}
	# Once the bin with the maximal difference is determine, calculate the
	# ratio of the partial sums of reads between the IP and input channels 
	# up to the determined bin number
	my $partial_sum_ip_reads = 0;
	my $partial_sum_input_reads = 0;
	for ( my $i = 0; $i < $maximum_bin_and_percentage_difference->{bin};
		$i++) {
		$partial_sum_ip_reads +=
		$ip_reads_per_interval->{$ordered_intervals->[$i]};
		$partial_sum_input_reads +=
		$input_reads_per_interval->{$ordered_intervals->[$i]};
	}
	my $sequencing_depth_scaling_factor = $partial_sum_ip_reads /
	$partial_sum_input_reads;
	return $sequencing_depth_scaling_factor;
}

# The _count_reads subroutine is a private subroutine which will count the
# number of lines in a given BED file, which is the number of reads for
# that channel

sub _count_reads {
	my ($self, $file_handle) = @_;
	my @file = <$file_handle>;
	my $number_of_reads = @file;
	return $number_of_reads;
}

# The _reads_per_interval subroutine is a private subroutine, which uses
# intersectBed to determine the number of reads from the IP and input
# channels, which overlap with the index_file of non-overlapping intervals.
# A Hash Ref of coordinates as keys and number of reads as values as well
# as an Array Ref of the ordered index of coordinates are returned to the 
# main subroutine.

sub _reads_per_interval {
	my $self = shift;
	# Run the _intersect_bed subroutine to return a Hash Ref of reads per
	# coordinate.
	my $input_reads_per_interval = $self->_intersect_bed($self->input_bed);
	my $ip_reads_per_interval = $self->_intersect_bed($self->ip_bed);
	my @ordered_intervals = sort { $ip_reads_per_interval->{$a} cmp
	$ip_reads_per_interval->{$b} } keys %$ip_reads_per_interval;
	return ($input_reads_per_interval, $ip_reads_per_interval,
		\@ordered_intervals);
}

# The _intersect_bed subroutine is a private subroutine called by
# _reads_per_interval. Given a File::Temp object corresponding to the
# input/ip reads, a command string for intersectBed is defined and executed
# using SDS::SamToBed::run_command is defined and executed, then the
# resulting output is parsed and returned to _reads_per_interval as a Hash
# Ref.

sub _intersect_bed {
	my ($self, $file_handle) = @_;
	# Create a File::Temp object to hold the output of the intersectBed
	# call
	my $temp_reads_per_interval = File::Temp->new(
		SUFFIX	=>	'_reads_per_interval.bed',
	);
	# Create a command for intersectBed to execute
	my $intersect_bed_command = 'intersectBed -c -a ' . $self->index_file .
	' -b ' . $file_handle . ' > ' . $temp_reads_per_interval;
	$self->executor->run_command($intersect_bed_command);
	# Pre-declare a Hash Ref to store the reads per interval
	my $reads_per_interval = {};
	while (<$temp_reads_per_interval>) {
		my $line = $_;
		chomp($line);
		my ($chr, $start, $stop, $reads) = split(/\t/, $line);
		$reads_per_interval->{$chr . ':' . $start . '-' . $stop} = $reads;
	}
	return $reads_per_interval;
}

1;

__END__

=head1 NAME

SDS::Algorithm

=head1 SYNOPSIS

my $sds_algorithm = SDS::Algorithm->new(
	input_bed	=>	input_reads.bed,
	ip_bed		=>	ip_reads.bed,
	# The index_file should be created with a File::Temp object which
	# points to the BED file containing the non-overlapping genomic
	# intervals.
	index_file	=>	File::Temp,
);

# Use the calculate_scaling_factor subroutine to return the scaling factor
my $sequence_scaling_factor = $sds_algorithm->calculate_scaling_factor;

=head1 AUTHOR

Jason R Dobson, C<< <dobson187 at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sds at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SDS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SDS::Algorithm


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


