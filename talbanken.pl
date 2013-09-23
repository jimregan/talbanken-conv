#!/usr/bin/perl

use warnings;
use strict;
use utf8;

use XML::Parser;

my $parser = XML::Parser->new(Handlers => {Start=>\&handle_start});
$parser->parsefile($ARGV[0]) or die "$!\n";

my $input;
my $reading = 0;

if($ARGV[1]) {
	open($input, "<$ARGV[1]") or die "$!\n";
} else {
	$input = *STDIN;
}
binmode $input, ":utf8";
binmode STDOUT, ":utf8";

my %mappings = ();

while (<$input>) {
	chomp;
	next if (/^#/);
	s/#.*$//;
	my @ln = split/\t/;
	if ($ln[2] eq '') {
		print "Error in mappings: no output ($_)\n";
	}
	if ($ln[0] ne '') {
		$mappings{"$ln[0]/$ln[1]"} = $ln[2];
	} else {
		$mappings{$ln[1]} = $ln[2];
	}
}

sub handle_start {
	
}
