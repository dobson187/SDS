package SDS::SamToBed;

use Moose;
use Carp;
use File::Temp;
use IPC::Open3;
use Symbol qw(gensym);
use Pod::Usage;

# This section contains the Moose constructor declarations

has sam_file	=>	(
	is			=>	'ro',
	isa			=>	'Str',
	required	=>	1,
);

# The convert subroutine is the main subroutine called by the SDS.pm
# controller. It will make system calls to samtools and bamToBed
# to convert the user-defined SAM file to a BED file. A File::Temp object
# containing the path to the converted BED file is returned to the SDS>pm
# controller module.

sub convert {
	my $self = shift;
	# Convert the SAM file to a BAM file. Capture any errors and kill the
	# program returning a message the user if there are any.
	# 
	# Create a File::Temp object to store the BAM file.
	my $temp_bam = File::Temp->new(
		SUFFIX	=>	'.BAM',
	);
	# Define a string for the command to be executed
	my $sam_to_bam_cmd = "samtools view -bS " . $self->sam_file . " > " .
	$temp_bam;
	$self->run_command($sam_to_bam_cmd);
	# Create a Temp::File object to store the temporary sorted BAM file
	my $temp_sorted_bam = File::Temp->new(
		SUFFIX	=>	'_sorted',
	);
	# Define a string for the command which will be executed to run the
	# samtools sort function
	my $sort_bam_command = 'samtools sort ' . $temp_bam . ' ' .
	$temp_sorted_bam;
	# Execute the command using the run_command subroutine
	$self->run_command($sort_bam_command);
	# Create a File::Temp object to store the temporary BED-format file,
	# which will be created by bamToBed
	my $temp_bed = File::Temp->new(
		SUFFIX	=>	'_Raw_Reads.bed'
	);
	# Define a string for the command for bamToBed which will be executed
	my $bam_to_bed_command = 'bamToBed -i ' . $temp_sorted_bam . '.bam > ' .
	$temp_bed;
	# Execute the command using the run_command subroutine
	$self->run_command($bam_to_bed_command);
	# Because the File::Temp object created for the $temp_sorted_bam was
	# not created with a .bam extension, but samtools adds the extension,
	# we have to manually remove this file when we are finished with it.
	# Define a removal string.
	my $rm_sorted_bam = 'rm ' . $temp_sorted_bam . '.bam';
	# Execute the command
	$self->run_command($rm_sorted_bam);
	# Return the File::Temp object for the temporary BED file of reads
	return $temp_bed;
}

# The run_command subroutine is passed a File::Temp object and an execution
# string. This subroutine will execute the command, and if any errors
# occur, SDS will stop execution and return an error message to the user.

sub run_command {
	my ($self, $command_string) = @_;
	# Pre-define Glob Refs that will be filled with any messages from the
	# samtools execution
	my ($in, $out, $error);
	$error = gensym;
	# Execute the command, and capture STDOUT and STDERR
	my $pid = open3( 
		$in,
		$out,
		$error,
		$command_string
	);
	# Wait for the process to finish
	waitpid($pid, 0);
	# Capture the exit status of the process
	my $exit_status = $? >> 8;
	# 0 is a successful exit, if it is otherwise, kill the program sending
	# an error message to the user.
	if ( $exit_status != 0 ) {
		my @errors = <$error>;
		pod2usage(
				-message	=>	"\n\nError message from samtools/bedtools:\n" .
				join("\n", @errors) . "\nPlease check that you have enetered the correct path to a valid SAM-format file\n\n",
				-verbose	=>	1,
				-exitval	=>	2,
				-input		=>	"$FindBin::Bin/../lib/SDS.pm",
		);
	}
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

SDS::SamToBed

=head1 SYNOPSIS

my $sam_to_bed = SDS::SamToBed->new(
	sam_file	=>	my_reads.SAM,
);

# Return a File::Temp object corresponding to the BED format file for the
# reads.
my $bed_format_reads_file_object = $sam_to_bed->convert;

=head1 AUTHOR

Jason R Dobson, C<< <dobson187 at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sds at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SDS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SDS::SamToBed


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
