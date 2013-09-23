#!/usr/bin/perl

use warnings;
use strict;
use utf8;

use XML::Parser;
use Data::Dumper;

my $sample = <<__END__;
<w pos="NN" msd="NN.UTR.SIN.DEF.NOM" lemma="|motortrafikled|" lex="|motortrafikled..nn.1|" saldo="|motortrafikled..1|" prefix="|motor..nn.1|" suffix="|trafikled..nn.1|" ref="1" dephead="2" deprel="SS">Motortrafikleden</w>
__END__

my $input;

if($ARGV[1]) {
	open($input, "<$ARGV[1]") or die "$!\n";
} else {
	$input = *STDIN;
}
binmode $input, ":utf8";
binmode STDOUT, ":utf8";


my %mappings = ();

my $lemma = "";
my $surface = "";
my $msd = "";
my $prefix = "";
my $suffix = "";
my %attribs = ();

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

my $parser = XML::Parser->new(Handlers => {Start=>\&handle_start, Char=>\&handle_char, End=>\&handle_end});
$parser->parsefile($ARGV[0]) or die "$!\n";
#$parser->parse($sample) or die "$!\n";
my $reading = 0;

sub handle_start {
	my ($expat, $element, %attrs) = @_;
	if ($element eq 'w') {
		$lemma = $attrs{'lemma'};
		$msd = $attrs{'msd'};
		$prefix = $attrs{'prefix'};
		$suffix = $attrs{'suffix'};
		%attribs = %attrs;
	}	
}

sub handle_char {
	$surface = $_[1];
}

sub handle_end {
	my ($expat, $element) = @_;
	if ($element eq 'w') {
		my $outtags = "";
		if ($lemma eq '|') {
			$lemma = $surface;
		} else {
			$lemma =~ s/^\|//;
			$lemma =~ s/\|$//;
			# dependency shit
			$lemma =~ s/:[0-9]*//g;
			if ($lemma =~ /\|/) {
				my @lemtmp = split/\|/, $lemma;
				if (exists $mappings{"$lemma/$msd"}) {
					$lemma = $lemtmp[0];
				}
			}		
		}
		if (exists $mappings{"$lemma/$msd"}) {
			$outtags = $mappings{"$lemma/$msd"};
		} elsif (exists $mappings{$msd}) {
			$outtags = $mappings{$msd};
		} else {
			print STDERR "Error: missing mapping ($msd)\n";
		}

		if ($outtags eq '*') {
			print "^*$surface\$ ";
		elsif (substr($outtags,0,1) ne '<') {
			print "^$surface/${outtags}\$ ";
		} else {
			print "^$surface/$lemma${outtags}\$ ";
		}

		# Reset
		$lemma = "";
		$msd = "";
		$suffix = "";
		$prefix = "";
		%attribs = ();
	}
}
