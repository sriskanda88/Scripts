#!/usr/bin/perl

use constant;
use Data::Dumper;
use String::Util 'trim';

my %gadget_hash;

sub main(){

    if (@ARGV != 3){
        printf("Usage: $0 <target_gadgets_dump> <gadgets_definition_file> <is_bb_gadget>\n");
        exit(0);
    }

    my $gadgets_file = $ARGV[0];
    my $gadget_defs_file = $ARGV[1];
    my $is_bbgadget = $ARGV[2];

    my @target_gadgets_list;
    my @gadget_def_list;

    build_gadgets_list($gadgets_file, \@target_gadgets_list, 1);
    build_gadgets_list($gadget_defs_file, \@gadget_def_list, $is_bbgadget);
    find_gadgets(\@target_gadgets_list, \@gadget_def_list, $is_bbgadget);
}

sub build_gadgets_list{

    my ($gadgets_file, $target_gadgets_list_ref, $is_bbgadget) = @_;
    my $isPartOfGadget = 0;
    my $currGadget;

    open FILE, "<$gadgets_file" or die "Unable to open the gadgets file";

    while ($line = <FILE>){
        if (($is_bbgadget && $line =~ m/\<.*\>:/) || (!$is_bbgadget && $line =~ m/^\s*$/ && !$isPartOfGadget)){
            $isPartOfGadget = 1;
            my @newGadget = ();
            $currGadget = \@newGadget;
            if (!$is_bbgadget){
                push(@$currGadget, $line);
            }
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
    my ($target_gadgets_list_ref, $gadget_defs_list_ref, $is_bbgadget) = @_;
    my @target_list = @$target_gadgets_list_ref;
    my @defs_list = @$gadget_defs_list_ref;
    my @matched_gadgets_list;
    my @unmatched_gadgets_list;

    foreach $def_gadget (@defs_list){
        my $isMatch = 0;
        foreach $target_gadget (@target_list){
            $isMatch = match_gadgets($target_gadget, $def_gadget, $is_bbgadget);
            if ($isMatch){
                print "============================================================\n";
                print @$target_gadget;
                print "------------------------------------------------------------\n";
                print @$def_gadget;
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
    printf("Percentage of basic block gadgets found : %d\%\n", (100*(scalar @matched_gadgets_list))/(scalar @defs_list));
}

sub match_gadgets{
    my ($gadget_ref1, $gadget_ref2, $is_bbgadget) = @_;
    my @gadget1 = @$gadget_ref1;
    my @gadget2 = @$gadget_ref2;
    my $gadget_bytes1, $gadget_bytes2;

    if ($is_bbgadget){

        if ($#gadget1 != $#gadget2) {
            return 0;
        }
        for (my $i = 0; $i <= $#gadget1; $i++){
            if (!match_instructions($gadgets1[$i], $gadget2[$i])){
                return 0;
            }
        }

        return 1;
    }
    else {
        my $matched_length = 0;
        for (my $i = 0; $i <= $#gadget1 - $#gadget2; $i++){
            $matched_length = 0;
            for (my $j = 0; $j <= $#gadget2; $j++){
                if (!match_instructions($gadget1[$i + $j], $gadget2[$j])){
                    last;
                }
                $matched_length++;
            }

            if ($matched_length == $#gadget2 + 1){
                return 1;
            }
        }

        return 0;
    }
}

sub match_instructions{
    my ($inst1, $inst2) = @_;

    $inst_bytes1 = (split(/:/, $inst1))[1];
    $inst_bytes2 = (split(/:/, $inst2))[1];

    $inst_bytes1 =~ /(([0-9a-f][0-9a-f] )+)/;
    $inst_bytes1 = trim($1);

    $inst_bytes2 =~ /(([0-9a-f][0-9a-f] )+)/;
    $inst_bytes2 = trim($1);

    return ($inst_bytes1 eq $inst_bytes2);

}

main();
#test();

sub test{
    my $str = "00 11 22   test %(ebx), eax";    
#    my $newstr = (split(/[a-za-za-z]/, str))[1];
    $str =~ /(([0-9a-f][0-9a-f] )+)/;
    print $1."\n";
}
