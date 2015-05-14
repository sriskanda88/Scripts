#!/usr/bin/perl

$dump = $ARGV[0];
open FL, "<$dump" or die "Unable to open file";

my $func_name = "";
my $prev_func_name = "";
my $func_addr = "";
my $prev_func_addr = "";
my $prev_inst_addr = "";
my $line = "";

while ($line = <FL>){
    if ($line ne ""){
        $prev_inst_addr = substr($line, 0, 8);
    }

    if ($line =~ m/<(.*)>:/ && $line !~ m/Lbuild/){
        $prev_func_name = $func_name;
        $func_name = $1;

        $prev_func_addr = $func_addr;
        $func_addr = "0x".(split(/ /, $line))[0];

        my $prev_func_size = hex($prev_inst_addr) - hex($prev_func_addr);

        if ($prev_func_name ne ""){
            print "$prev_func_name:$prev_func_addr:$prev_func_size\n";
        }
    }
}

close(FL);
