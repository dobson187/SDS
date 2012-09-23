package SDS::Index;

use Moose;
use FindBin;
use Pod::Usage;
use File::Temp;
use Data::Dumper;

# The following section contains the Moose constructor declarations.

has chromosome_sizes	=>	(
	is				=>	'ro',
	isa				=>	'HashRef[Int]',
	required		=>	1,
);

has sds_interval	=>	(
	is				=>	'ro',
	isa				=>	'Int',
	required		=>	1,
);

# The create_index subroutine is the main function called by the SDS.pm
# controller module of SDS. create_index partitions the genome defined in
# the chromosome_sizes Hash Ref, into n non-overlapping intervals of size
# sds_interval. The coordinates will be written to a File::Temp object,
# which is returned to the main SDS.pm module.

sub create_index {
	my $self = shift;
	# Pre-declare an Array Ref to hold the interval coordinates
	my $index_coordinates = [];
	# Iterate through the chromosomes, writing BED-format coordinates of
	# size sds_interval, which don't overlap and store the coordinates in
	# the index_coordinates Array Ref
	foreach my $chromosome (keys %{$self->chromosome_sizes} ) {
		for ( my $i = 0; $i <= $self->chromosome_sizes->{$chromosome}; $i
			+= $self->sds_interval ) {
			push (@$index_coordinates, 
				join("\t", $chromosome, $i, ($i + $self->sds_interval - 1))
			);
		}
	}
	# Create a File::Temp object to store the index coordinates, write the
	# coordinates to this file, and then return the File::Temp object to
	# the SDS.pm module.
	my $temp_index_file = File::Temp->new(
		SUFFIX	=>	'_non-overlapping_index_' . $self->sds_interval .
		'_bp.bed',
	);
	open my $temp_index_out, ">", $temp_index_file or die "Could not write to $temp_index_file, please check that you have the proper permissions to execute this program and have write access in the /tmp folder. $!\n";
	print $temp_index_out join("\n", @$index_coordinates);
	return $temp_index_file;
}

1;

__END__

=head1 NAME

SDS::Index

=head1 SYNOPSIS



=head1 AUTHOR

Jason R Dobson, C<< <dobson187 at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sds at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SDS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SDS::Index


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

