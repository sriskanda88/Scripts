#!/usr/bin/perl

use constant;
use Data::Dumper;
use String::Util 'trim';

my %gadget_hash;

sub main(){

	if (@ARGV != 2){
		printf("Usage: $0 <target_gadgets_dump> <gadgets_definition_file>\n");
		exit(0);
	}

	my $gadgets_file = $ARGV[0];
	my $gadget_defs_file = $ARGV[1];

	my @target_gadgets_list;
	my @gadget_def_list;

	build_gadgets_list($gadgets_file, \@target_gadgets_list);
	build_gadgets_list($gadget_defs_file, \@gadget_def_list);
	find_gadgets(\@target_gadgets_list, \@gadget_def_list);
}

sub build_gadgets_list{

	my ($gadgets_file, $target_gadgets_list_ref) = @_;
	my $isPartOfGadget = 0;
        my $currGadget, $currBBaddr;

	open FILE, "<$gadgets_file" or die "Unable to open the gadgets file";

	while ($line = <FILE>){
                if ($line =~ m/\<.*\>:/){
                        $isPartOfGadget = 1;
                        $currBBaddr = (split(/ /,$line))[0];
                        my @newGadget = ();
                        $currGadget = \@newGadget;
                }
                elsif (($line =~ m/ret/) && $isPartOfGadget){
                        push(@$currGadget, $line);
                        my $gadget_size = (scalar (@$currGadget)) - 1;
                        push(@$target_gadgets_list_ref, $currGadget);
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

sub find_gadgets{
	my ($target_gadgets_list_ref, $gadget_defs_list_ref) = @_;
	my @target_list = @$target_gadgets_list_ref;
	my @defs_list = @$gadget_defs_list_ref;
	my @matched_gadgets_list;
	my @unmatched_gadgets_list;

	foreach $def_gadget (@defs_list){
		my $isMatch = 0;
		foreach $target_gadget (@target_list){
			$isMatch = match_gadgets($def_gadget, $target_gadget);
			if ($isMatch){
				print "============================================================\n";
				print @$def_gadget;
				print "------------------------------------------------------------\n";
				print @$target_gadget;
				last;
			}	
		}

		if ($isMatch){
			push(@matched_gadgets_list, $def_gadget);
		}
		else{
			push(@unmatched_gadgets_list, $def_gadget);
		}	
	}

	printf("Number of gadgets to find: %d\n", scalar @defs_list);
	printf("Number of gadgets found: %d\n", scalar @matched_gadgets_list);
	printf("Number of gadgets searched: %d\n", scalar @target_list);
	printf("Percentage of basic block gadgets found : %d\n", (scalar @matched_gadgets_list)/(scalar @defs_list));
}

sub match_gadgets{
	my ($gadget_ref1, $gadget_ref2) = @_;
	my @gadget1 = @$gadget_ref1;
	my @gadget2 = @$gadget_ref2;
	my $gadget_bytes1, $gadget_bytes2;

	if ($#gadget1 != $#gadget2) {
		return 0;
	}

#	print "============================================================\n";

	for (my $i = 0; $i < $#gadget1; $i++){
		$gadget_bytes1 = (split(/:/, $gadget1[$i]))[1];
		$gadget_bytes2 = (split(/:/, $gadget2[$i]))[1];

		$gadget_bytes1 =~ /(([0-9a-f][0-9a-f] )+)/;
		$gadget_bytes1 = trim($1);
	
		$gadget_bytes2 =~ /(([0-9a-f][0-9a-f] )+)/;
		$gadget_bytes2 = trim($1);

#		print $gadget_bytes1."  ::  ".$gadget_bytes2."\n";

		if ($gadget_bytes1 ne $gadget_bytes2){
			return 0;
		}	
	}

	return 1;
}

main();
#test();

sub test{
	my $str = "00 11 22   test %(ebx), eax";	
#	my $newstr = (split(/[a-za-za-z]/, str))[1];
	$str =~ /(([0-9a-f][0-9a-f] )+)/;
	print $1."\n";
}
