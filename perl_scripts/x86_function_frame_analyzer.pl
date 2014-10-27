#!/usr/bin/perl

$dump = $ARGV[0];
open FL, "<$dump" or die "Unable to open file";

$rec = 0;
$pushcount = 0;
$buff = 0;
$func_name = "";
$func_addr = "";

while ($line = <FL>){
    if ($line =~ m/<(.*)>:/){
        $rec = 1;
        $pushcount = 0;
        $buff = 0;
        $func_name = $1;
        $func_addr = "0x".(split(/ /, $line))[0];
#        print "$func_name : $func_addr\n";
    }

    if ($rec == 0){
        next;
    }

    if ($line =~ m/push/){
#        print "$line\n";
        $pushcount++;
    }

    if ($line =~ m/sub\s+\$(.*),\%esp/){
#        print $line;
        $buff = hex($1);
        printf("%s:%s:%d\n", $func_name, $func_addr, $buff + ($pushcount * 4));
        $rec = 0;
    }
}

close(FL);
