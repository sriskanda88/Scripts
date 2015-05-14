#!/usr/bin/perl

use constant;
use Data::Dumper;
use Cwd 'abs_path';
use File::Path qw( rmtree );

my %gadget_hash;

sub main(){
	my $bmobjdump = $ARGV[0];
	my $bmname;

	if (@ARGV == 0){
		printf("Specify the benchmark objdump file, idiot.\n");
		exit(0);
	}

	buildGadgetHash($bmobjdump);
	printGadgets();
}

sub printGadgets(){
	foreach my $bb_addr (sort keys %gadget_hash){
		my $bb_name = $gadget_hash{$bb_addr};
		print "$bb_addr : $bb_name";
	}
}

sub buildGadgetHash(){
	my ($bmobjdump) = @_;
	my $isPartOfGadget = 0;
	my $currBBaddr, $prevBBaddr, $currBBname, $prevBBname;

	open FILE, "<$bmobjdump" or die "Unable to open objdump file, idiot";
	
	while ($line = <FILE>){
		if ($line =~ m/\<.*\>:/){
			$isPartOfGadget = 1;
			$prevBBaddr = $currBBaddr;
			$prevBBname = $currBBname;
			($currBBaddr, $currBBname) = (split(/ /,$line));
		}
		#elsif (($line =~ m/jmp.*\*/) && $isPartOfGadget){ # || $line =~ /ret/) && $isPartOfGadget){
		elsif (($line =~ m/jmp.*\*/ || $line =~ /ret/) && $isPartOfGadget){
			$gadget_hash{$currBBaddr} = $currBBname;
			$isPartOfGadget = 0;
		}
		elsif (($line =~ m/call.*\*/) && $isPartOfGadget){
			$gadget_hash{$prevBBaddr} = $prevBBname;
			$isPartOfGadget = 0;
		}
		elsif (($line =~ m/^\s*$/) && $isPartOfGadget){
			$isPartOfGadget = 0;			
		}
	}

	close FILE;	
}

main();
