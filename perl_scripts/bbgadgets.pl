#!/usr/bin/perl

use constant;
use Data::Dumper;
use Cwd 'abs_path';
use File::Path qw( rmtree );

my %gadget_hash;
my $out_path = "/tmp/";

sub main(){
	my $bmobjdump = $ARGV[0];
	my $size = -1;
	my $isPrintToFile = 0;
	my $bmname, $out_dir;

	if (@ARGV == 0){
		printf("Specify the benchmark objdump file, idiot. Oh, also use \"-f\" at the end if you want it all in a file in /tmp.\n");
		exit(0);
	}
	if (@ARGV == 2 && $ARGV[1] == "-f"){		
		$isPrintToFile = 1;
		$bmname = (split(/\./,(split(/\//,abs_path($bmobjdump)))[-1]))[0];
		$out_dir = $out_path.$bmname."-gadgets";

		if (-d $out_dir){
			rmtree($out_dir);
		}
		
		mkdir($out_dir, 0755);
	}

	buildGadgetHash($bmobjdump);
	
	#Dump found gadgets to file	
	if ($isPrintToFile){
		printGadgetsToFile($out_dir, $bmname); 
	}
	else{
		#print gadget sizes available for interactive display
		printGadgetSizes();

		while ($size != 0){
			printf("Choose a gadget size (0 to exit): ");
			$size = <STDIN>;
			chomp($size);
		 
			while (($size == -1) || ($size !~ m/[0-9]+/)){
				printf("Enter a number, idiot: ");	
				$size = <STDIN>;
				chomp($size);
			}
		
			if ($size > 0){
				system("clear");
				printGadgets($size);
				printGadgetSizes();
			}
		}
	}
}

sub printGadgetsToFile(){
	my ($out_dir, $bmname) = @_;
	my $out_file_combined = $out_dir."/".$bmname;
	
	foreach my $size (sort { $a <=> $b } (keys %gadget_hash)){
		my $out_file = $out_dir."/".$bmname.".".$size;
		open FILE, ">$out_file" or die "Unable to open file to write to!";
		
		my $sizeHashRef = $gadget_hash{$size};
		foreach my $addr (keys %$sizeHashRef){
	                my $gadgetRef = $gadget_hash{$size}{$addr};
        	        print FILE @$gadgetRef;
                	print FILE "\n";
		}
	
		close FILE;
		system("cat $out_file >> $out_file_combined");
	}
}

sub printGadgets(){
	my ($size) = @_;
	my $sizeHashRef = $gadget_hash{$size};
	foreach my $addr (keys %$sizeHashRef){
		my $gadgetRef = $gadget_hash{$size}{$addr};
		print @$gadgetRef;
		print "\n";
	}
}

sub printGadgetSizes(){
	printf("Gadget sizes available: ");
	foreach my $key (sort { $a <=> $b } (keys %gadget_hash)){
		printf("%d ", $key);
	}
	printf("\n");
}

sub buildGadgetHash(){
	my ($bmobjdump) = @_;
	my $isPartOfGadget = 0;
	my $currGadget, $currBBaddr;

	open FILE, "<$bmobjdump" or die "Unable to open objdump file, idiot";
	
	while ($line = <FILE>){
#		chomp($line);

		if ($line =~ m/.*Lbuild.*/){
			$isPartOfGadget = 1;
			$currBBaddr = (split(/ /,$line))[0];
			my @newGadget = ();
			$currGadget = \@newGadget;	
			push(@$currGadget, $line);
		}
		elsif (($line =~ m/ret /) && $isPartOfGadget){
			push(@$currGadget, $line);
			my $gadget_size = (scalar (@$currGadget)) - 1;
			$gadget_hash{$gadget_size}{$currBBaddr} = $currGadget;
			$isPartOfGadget = 0;
		}
		elsif (($line =~ m/^\s*$/) && $isPartOfGadget){
			$isPartOfGadget = 0;			
		}
		elsif ($isPartOfGadget){
			push(@$currGadget, $line);
		}
	}

	close FILE;	
}

main();
