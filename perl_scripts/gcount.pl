#!/usr/bin/perl

use constant;
use Data::Dumper;

use constant{NAME=>"name", ADDR=>"addr", SIZE=>"size", END_ADDR=>"end_addr", GCOUNT=>"gcount", GLIST=>"glist", CODE=>"code"};

sub main(){
	my $bm = $ARGV[0];
	my @gadget_list;
	my @func_list;
	my %gadget_hash;
	my %func_hash;
	
	$bm = "/home/skanda//proj/benchmarks/x86/bzip2/bzip2";

	#Configs
	my $page_size = 4096;
	my $logfile = "/tmp/gcount-test-log";

	@gadget_list = `ROPgadget $bm 2>&1 | grep : | grep 0x`;
	@func_list = `readelf -a $bm | grep FUNC 2>/dev/null`;	
	
	#get gadgets, function names, addresses and sizes
	populateGadgetHashFromList(\@gadget_list, \%gadget_hash);
	populateFuncHashFromList(\@func_list, \%func_hash);
	
	#get total gadget count
	my $total_gadget_count = getTotalGagetCount(\@gadget_list);
	my $gadgets_per_page = getGadgetsPerPage(\%gadget_hash, $page_size);
	my $gadgets_per_func = getGadgetsPerFunc(\%gadget_hash, \%func_hash);

	print "Total gadgets found: $total_gadget_count\n";
	printf("Avg num of gadgets in pages with gadgets: %.3f\n", $gadgets_per_page);
	printf("Avg num of gadgets in functions with gadgets: %.3f\n", $gadgets_per_func);
	
	#log data to file
	logdata($logfile, \%gadget_hash, \%func_hash);
	
	return 0;
}

sub getTotalGagetCount(){
	my $gadget_list = $_[0];
	return $#$gadget_list;
}

sub getGadgetsPerPage(){
	my ($gadget_hash, $page_size) = @_;
	my %page_addr_hash;
	my @gadget_list = keys %gadget_hash;	
	
	foreach $gadget (@gadget_list) {
		my $addr_decimal = hex($gadget);
		my $page_num = int($addr_decimal/$page_size);
		$page_addr_hash{$page_num} = (exists($page_addr_hash{$page_num})? $page_addr_hash{$page_num} : 0) + 1;
	}
	
	my @page_num_list = keys %page_addr_hash;
	
	return $#gadget_list/$#page_num_list;
}

sub getGadgetsPerFunc(\@\%){
	my ($gadget_hash, $func_hash) = @_;
	my @gadget_list = keys %gadget_hash;
	my $func_count = 0;
	my $gadget_count = 0;
	
	foreach my $gadget (@gadget_list){
		chomp($gadget);
		foreach my $func (keys %func_hash){
			my $g_addr = hex($gadget);
			if ($g_addr >= $func_hash{$func}{ADDR} && $g_addr <= $func_hash{$func}{END_ADDR}){
				if (!exists($func_hash{$func}{GCOUNT})){
					$func_hash{$func}{GCOUNT} = 1;
					$func_hash{$func}{GLIST} = ($gadget);					
				}
				else{
					$func_hash{$func}{GCOUNT} += 1;
					push(@{$func_hash{$func}{GLIST}}, $gadget);					
				}
			}
		}
	}

	foreach my $func (keys %func_hash){
		if (exists($func_hash{$func}{GCOUNT})){
			$func_count++;
			$gadget_count += $func_hash{$func}{GCOUNT};
		}
	}
	
	return $gadget_count/$func_count;
}

sub populateFuncHashFromList(){
	my ($func_list, $func_hash) = @_;
	
	foreach my $func (@$func_list){
		my ($addr, $size, $name) = (split(/[: ]+/,$func))[2,3,8];
		chomp($name);
		$func_hash{$name}{NAME} = $name;
		$func_hash{$name}{ADDR} = hex($addr);
		$func_hash{$name}{SIZE} = $size;
		$func_hash{$name}{END_ADDR} = hex($addr) + $size;
	}
}

sub populateGadgetHashFromList(){
	my ($gadget_list, $gadget_hash) = @_;
	
	foreach my $gadget (@$gadget_list){
		my ($addr, $code) = (split(/: /,$gadget))[0,1];
		chomp($code);		
		$gadget_hash{$addr}{ADDR} = $addr;
		$gadget_hash{$addr}{CODE} = $code;
	}
}

sub logdata(){
	my ($logfile, $gadget_hash, $func_hash) = @_;
	
	open FILE, ">$logfile" or die $!;
	
	printf(FILE "%-30s%-10s%-10s\n", 'Function name', 'Address', 'Num of Gadgets');
	
	foreach my $func (keys %func_hash){
		if ($func_hash{$func}{GCOUNT}>0){
			printf(FILE "%-30s%10d%3d\n", $func_hash{$func}{NAME}, $func_hash{$func}{ADDR}, $func_hash{$func}{GCOUNT});
		}
	}
	
	close FILE;
}

#call main here
exit main()
