package SDS::Genome;

use Moose;
use SDS::UCSC;
use Carp;
use Pod::Usage;
use FindBin;
use File::Temp;

# This section is for the Moose constructor declarations

has genome	=>	(
	is			=>	'ro',
	isa			=>	'Str',
	required	=>	1,
);

has genome_info	=>	(
	is			=>	'ro',
	isa			=>	'HashRef[Int]',
	required	=>	1,
	default		=>	sub {
		my $self = shift;
		my $genome_info = {
			hg19	=>	1,
			hg18	=>	1,
			hg17	=>	1,
			hg16	=>	1,
			panTro3	=>	1,
			panTro2	=>	1,
			panTro1	=>	1,
			ponAbe2	=>	1,
			rheMac2	=>	1,
			calJac3	=>	1,
			calJac1	=>	1,
			mm10	=>	1,
			mm9		=>	1,
			mm8		=>	1,
			mm7		=>	1,
			rn5		=>	1,
			rn4		=>	1,
			rn3		=>	1,
			cavPor3	=>	1, 
			oryCun2	=>	1,
			oviAri1	=>	1,
			bosTau7	=>	1,
			bosTau6	=>	1,
			bosTau4	=>	1,
			bosTau3	=>	1,
			bosTau2	=>	1,
			equCab2	=>	1,
			equCab1	=>	1,
			felCat4	=>	1,
			felCat3	=>	1,
			canFam3	=>	1,
			canFam2	=>	1,
			canFam1	=>	1,
			monDom5	=>	1,
			monDom4	=>	1,
			monDom1	=>	1,
			ornAna1	=>	1,
			galGal4	=>	1,
			galGal3	=>	1,
			galGal2	=>	1,
			taeGut1	=>	1,
			xenTro3	=>	1,
			xenTro2	=>	1,
			xenTro1	=>	1,
			danRer7	=>	1,
			danRer6	=>	1,
			danRer5	=>	1,
			danRer4	=>	1,
			danRer3	=>	1,
			fr3		=>	1,
			fr2		=>	1,
			fr1		=>	1,
			gasAcu1	=>	1,
			oryLat2	=>	1,
			dm3		=>	1,
			dm2		=>	1,
			dm1		=>	1,
			ce10	=>	1,
			ce6		=>	1,
			ce4		=>	1,
			ce2		=>	1,
			ce10	=>	1,
		};
		return $genome_info;
	},
);

# This is the main subroutine called by the controller SDS.pm module
sub chromosome_sizes {
	my $self = shift;
	# Check to make sure the genome entered is valid.
	$self->_valid_genome;
	# Now that the genome has been validated, connect to the UCSC database
	# for the user-defined genome.
	my $schema =
	SDS::UCSC->connect('dbi:mysql:host=genome-mysql.cse.ucsc.edu;database='
		. $self->genome, "genome") or croak "\n\nError establishing a connection to the UCSC database for the " . $self->genome . " genome.\n\n";
	# Get the chromosome sizes information from UCSC
	my $raw_chrom_sizes = $schema->storage->dbh_do(
		sub {
			my ($storage, $dbh, @args) = @_;
			$dbh->selectall_hashref("SELECT chrom, size FROM chromInfo", ["chrom"]);
		},
	);
	# Pre-declare a Hash Ref and an Array Ref for the chromosome sizes. The
	# Hash Ref will be returned to the SDS controller module, while the
	# Array Ref will be written to a temporary file and the file handle
	# will also be returned to the SDS controller module.
	my $chromosome_sizes = {};
	my $chromosome_sizes_array = [];
	# Iterate through the chromosome information returned from UCSC, and
	# parse the info for the Hash and Array respectively.
	foreach my $chromosome (keys %$raw_chrom_sizes) {
		$chromosome_sizes->{$chromosome} =
		$raw_chrom_sizes->{$chromosome}{size};
		push(@$chromosome_sizes_array, join("\t", $chromosome,
				$raw_chrom_sizes->{$chromosome}{size}));
	}
	# Create a temporary file to print the chromosome sizes to
	my $chromosome_sizes_fh = File::Temp->new(
		SUFFIX	=>	'_' . $self->genome . '.chrom.sizes',
	);
	open my $chr_sizes_out, ">", $chromosome_sizes_fh or croak "\n\nUnable to write to $chromosome_sizes_fh, the temporary chromosome sizes file, please check that you have the proper permissions when executing this program.\n\n";
	print $chr_sizes_out join("\n", @$chromosome_sizes_array);
	return ($chromosome_sizes, $chromosome_sizes_fh);
}

# The following subroutine is used to determine whether the user-defined
# string for the genome is valid
sub _valid_genome {
	my $self = shift;
	unless ( $self->genome_info->{$self->genome} ) {
		pod2usage(
			-message	=>	"\n\nYou must define a valid genome. The genome: " . $self->genome  . " is not valid.\n\n",
			-verbose	=>	1,
			-exitval	=>	2,
			-input		=>	"$FindBin::Bin/../lib/SDS.pm",
		);
	}
}

1;

__END__

=head1 NAME

SDS::Genome

=head1 SYNOPSIS


=head1 SUBROUTINES/METHODS

=head2 function1

=head2 function2

=head1 AUTHOR

Jason R Dobson, C<< <dobson187 at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sds at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SDS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SDS::Genome


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
