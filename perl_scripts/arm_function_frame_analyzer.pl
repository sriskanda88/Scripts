#!/usr/bin/perl

$dump = $ARGV[0];
open FL, "<$dump" or die "Unable to open file";

$rec = 0;
$pushcount = 0;
$buff = 0;
$func_name = "";
$func_addr = "";

while ($line = <FL>){
    if (($line =~ m/<(.*)>:/) && ($line !~ m/Lbuild/)){
        $rec = 1;
        $pushcount = 0;
        $buff = 0;
        $func_name = $1;
        $func_addr = "0x".(split(/ /, $line))[0];
        next;
        #print "$func_name : $func_namenc_addr\n";
    }

    if ($rec == 0){
        next;
    }

    chomp($line);

    if ($line =~ m/push\s+{(.*)}.*/){
        @regs = split(/,/,$1);
        $pushcount += $#regs + 1;
        #print "$line : $pushcount\n";
        next;
    }

    if ($line =~ m/sub\s+sp.*sp.*#(.*)\s?/){
        $buff += $1;
        #print "$line : $buff\n";
    }
    else{
        printf("%s:%s:%d\n", $func_name, $func_addr, $buff + ($pushcount * 4));
        $rec = 0;
        next;
    }

}

close(FL);
