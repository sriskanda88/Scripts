#!/usr/bin/perl

use constant;
use Data::Dumper;

use constant{ ADDR=>"addr", END_ADDR=>"end_addr", GCOUNT=>"gcount", GLIST=>"glist", CODE=>"code"};

sub main(){
	my $bm = $ARGV[0];
	my @gadget_list;
	my %gadget_hash;
	my @instr_list;
	
	$bm = "/home/skanda/proj/benchmarks/x86/sphinx3/sphinx3";
	$trace_file = "/home/skanda/scratch/sphinx3-trace.out";

	#Configs
	my $logfile = "/home/skanda/scratch/sphinx3-switchcount.log";

	@gadget_list = `ROPgadget $bm 2>&1 | grep : | grep 0x`;
#	@instr_list = `cat $trace_file | cut -d ":" -f 4 | cut -c 2- | uniq`;

	#get gadgets, function names, addresses and sizes
	populateGadgetHashFromList(\@gadget_list, \%gadget_hash);

	#simulate switching and count instrs between switches
	simulateSwitching($trace_file, \%gadget_hash, $logfile);
	
	return 0;
}

sub simulateSwitching(){
	my ($trace_file, $gadget_hash, $logfile) = @_;
	my ($isa1, $isa2, $currisa) = (1, 2, 1);
	my $gPage = 0;
	my $inscount = 0;

	open LOG, ">$logfile" or die "Could not open logfile";
	open FL, "<$trace_file" or die "Could not open trace";
	
	while(<FL>){
		my $instr = (split(/: /, $_))[3];
		chomp($instr);
		my $instr_hex = hex($instr);
		my $instr_page = $instr_hex & 0xfffff000;

		if (exists($gadget_hash->{$instr_page})){
			if ($gPage != $instr_page){
				$currisa = (($currisa == $isa1)? $isa2 : $isa1);
#				printf("%d instructions executed\nSwitching to ISA %d\n", $inscount, $currisa);
				print LOG "$inscount\n";
				$gPage = $instr_page;
				$inscount = 0;
			}
		}
		$inscount++;
	}

	close FL;
	close LOG;
}

sub populateGadgetHashFromList(){
	my ($gadget_list, $gadget_hash) = @_;
	
	foreach my $gadget (@$gadget_list){
		my ($addr, $code) = (split(/: /,$gadget))[0,1];
		chomp($code);		
		my $page_start = hex($addr);
		$page_start = $page_start & 0xfffff000;
#		printf("%s : %x\n", $addr, $page_start);
		$gadget_hash->{$page_start}->{$addr} = $code;
	}
}

#call main here
exit main();
