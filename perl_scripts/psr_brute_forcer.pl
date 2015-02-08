#!/usr/bin/perl

use Data::Dumper;
use Math::Combinatorics;
use Statistics::Basic qw(:all);
use constant{GADGET=>"gadget", CLOBBER=>"clobber", STACK_MOD=>"stack_mod", RET_ADDR=>"ret_addr", FRAME_SIZE=>"frame_size", SUCCESS=>"success", TIME=>"time", NULL=>"null"};
use constant{DEBUG=>(0), DUMP=>(0), CHECK_STACK_CLOBBER=>(1), JITROP=>(0)};

my @full_reg_list = ("eax", "ecx", "edx", "ebx", "esp", "ebp", "esi", "edi");
my @reg_list = ("eax", "ecx", "edx", "ebx", "ebp", "esi", "edi");
my @val_list = ("0xb", "0x1234abcd", "0x1234abcd", "0x0");
#my @val_list = ("0x1234abcd", "0x1234abcd", "0x1234abcd", "0x1234abcd");

my @permutations;
my %gadgets_hash;
my %psr_hash;
my %exploit_hash;
my %loop_times_hash;

my $time_per_gadget = 1;
my $time_for_all_gadgets = 0;

my $max_frame_size = 8192;
my $total_gadgets = 0;

#max frame size for jitrop is just 1
$max_frame_size = 1 if JITROP;

sub main(){
    if ($#ARGV < 1){
        print "Usage: ./psr_brute_forcer.pl <gadgets_file> <psr_output_file> [<psr_output_file>,]\n";
        exit(0);
    }

    my $gadgets_file = $ARGV[0];
    my $gadget_num = 1;

    #read all gadgets into gadget list
    open(FL, "<$gadgets_file") or die "Unable to open gadgets file";
    while($line = <FL>){
        chomp($line);
        $gadgets_hash{$line} = $gadget_num;
        $gadget_num++;
    }
    close(FL);
    $total_gadgets = $gadget_num;
    $time_for_all_gadgets = $total_gadgets * $time_per_gadget;

    #read all psr outs into the hash
    for(my $i = 1; $i <= $#ARGV; $i++ ){
        open(FL, "<$ARGV[$i]") or die "Unable to open psr out files";
        while($line = <FL>){
            chomp($line);
            my ($gadget, $reg, $data, $clobber_free_list, $stack_modded, $ret, $frame_size) = split(/\|/, $line);
            foreach $clobber_free_reg (split(/\:/, $clobber_free_list)){
                $psr_hash{$reg}{$data}{$gadget}{CLOBBER}{$full_reg_list[$clobber_free_reg]} = 1;
            }
            $psr_hash{$reg}{$data}{$gadget}{STACK_MOD} = $stack_modded;
            $psr_hash{$reg}{$data}{$gadget}{RET_ADDR} = $ret;
            $psr_hash{$reg}{$data}{$gadget}{FRAME_SIZE} = $frame_size;
        }
        close(FL);
    }

    print Dumper(%psr_hash) if DUMP;
    print Dumper(%gadgets_hash) if DUMP;

    #start the analysis
    generate_permutations();

    #calculate loop times
    calculate_loop_times();
    print Dumper(%loop_times_hash) if DUMP;

    #analyze each permutation to find a valid exploit
    analyze_this();
    print Dumper(%exploit_hash) if DUMP;

    #print results
    print_results();
}

sub generate_permutations(){
    #generate all permuations

    my @combinations = combine(4, @reg_list);
    #print join("\n", map{join " ", @$_} @combinations) if DEBUG;

    foreach $c (@combinations){
        push(@permutations, $_) foreach permute(@$c);
        #print join("\n", map{ join " ", @$_ } @permutations), "\n" if DEBUG;
    }
}

sub analyze_this(){
    foreach $combo (@permutations){
        my $combo_str = join(" ", @$combo);
        print "COMBO => $combo_str\n" if DEBUG;

        my @clobber_free_list;
        $exploit_hash{$combo_str}{SUCCESS} = 1;

        for (my $i = 0; $i < 4; $i++){
            my $reg_value = $val_list[$i];
            my $reg_to_fill = @$combo[$i];
            my $winning_gadget = NULL;
            my $winning_gadget_ret_addr = 0;

            $exploit_hash{join(" ", @$combo)}{$reg_to_fill}{SUCCESS} = 1;

            print "REGISTER TO FILL : $reg_to_fill => $reg_value\n" if DEBUG;
            print "Regs to save: @clobber_free_list\n" if DEBUG;

            foreach $gadget (keys %{$psr_hash{$reg_to_fill}{$reg_value}}){
                # Continue if stack has been modified. search for something with an umodified stack
                if ($psr_hash{$reg_to_fill}{$reg_value}{$gadget}{STACK_MOD}){
                    print "Skipping $gadget since stack has been modified\n" if DEBUG;
                    next if CHECK_STACK_CLOBBER;
                }

                # Continue if clobber free list is not satisfied
                my $is_clobbered = 0;
                foreach $clobber_free_reg (@clobber_free_list){
                    if (!exists($psr_hash{$reg_to_fill}{$reg_value}{$gadget}{CLOBBER}{$clobber_free_reg})){
                        print "$clobber_free_reg is clobbered\n" if DEBUG;
                        $is_clobbered = 1;
                        break;
                    }
                }

                if ($is_clobbered){
                    print "Skipping $gadget since it's clobbered yo\n" if DEBUG;
                    next;
                }

                if ($winning_gadget eq NULL){
                    $winning_gadget = $gadget;
                    $winning_gadget_ret_addr = $psr_hash{$reg_to_fill}{$reg_value}{$gadget}{RET_ADDR};
                }
                else {
                    if ($psr_hash{$reg_to_fill}{$reg_value}{$gadget}{RET_ADDR} < $winning_gadget_ret_addr){
                        $winning_gadget = $gadget;
                        $winning_gadget_ret_addr = $psr_hash{$reg_to_fill}{$reg_value}{$gadget}{RET_ADDR};
                    }
                }

                #printf("@$combo : $reg_to_fill : $reg_value : $psr_hash{$reg_to_fill}{$reg_value}{$gadget}{FRAME_SIZE}\n");
            }

            if ($winning_gadget ne NULL){
                $exploit_hash{$combo_str}{$reg_to_fill}{GADGET} = $winning_gadget;
                $exploit_hash{$combo_str}{$reg_to_fill}{RET_ADDR} = $winning_gadget_ret_addr;
            }
            else {
                $exploit_hash{$combo_str}{$reg_to_fill}{SUCCESS} = 0;
                $exploit_hash{$combo_str}{SUCCESS} = 0;
            }

            push(@clobber_free_list, $reg_to_fill);
        }

        if ($exploit_hash{$combo_str}{SUCCESS} == 1){
            my $time_for_exploit = 0.0;
            for (my $i = 4; $i >= 1; $i--){
                my $reg_to_fill = @$combo[$i-1];

                $time_for_exploit += $gadgets_hash{$exploit_hash{$combo_str}{$reg_to_fill}{GADGET}} * $loop_times_hash{GADGET}{$i};
                $time_for_exploit += $exploit_hash{$combo_str}{$reg_to_fill}{RET_ADDR} * $loop_times_hash{RET_ADDR}{$i};
            }
            $exploit_hash{$combo_str}{TIME} = $time_for_exploit;
        }
    }
}

sub calculate_loop_times(){
    $loop_times_hash{GADGET}{4} = $time_per_gadget;
    $loop_times_hash{RET_ADDR}{4} = $loop_times_hash{GADGET}{4} * $total_gadgets;

    $loop_times_hash{GADGET}{3} = $loop_times_hash{RET_ADDR}{4} * $max_frame_size;
    $loop_times_hash{RET_ADDR}{3} = $loop_times_hash{GADGET}{3} * $total_gadgets;

    $loop_times_hash{GADGET}{2} = $loop_times_hash{RET_ADDR}{3} * $max_frame_size;
    $loop_times_hash{RET_ADDR}{2} = $loop_times_hash{GADGET}{2} * $total_gadgets;

    $loop_times_hash{GADGET}{1} = $loop_times_hash{RET_ADDR}{2} * $max_frame_size;
    $loop_times_hash{RET_ADDR}{1} = $loop_times_hash{GADGET}{1} * $total_gadgets;
}

sub print_results(){
    my $best_combo;
    my $least_time_to_exploit = 0.0;
    my $least_stddev = 0.0;

    print "Successful exploits :\n";
    printf("%-20s\t%-16s\t%-5s\t%-16s\t%-5s\t%-16s\t%-5s\t%-16s\t%-5s\t%-20s\t%-5s\n",
           "Combination", "Reg 1", "Ret 1", "Reg 2", "Ret 2", "Reg 3", "Ret 3", "Reg 4", "Ret 4", "Time", "StdDev");

    foreach $combo_str (keys %exploit_hash){
        if ($exploit_hash{$combo_str}{SUCCESS} == 0){
            next;
        }

        my @regs = split(/ /, $combo_str);
        my $vals = vector($gadgets_hash{$exploit_hash{$combo_str}{$regs[0]}{GADGET}}, $gadgets_hash{$exploit_hash{$combo_str}{$regs[1]}{GADGET}},
                          $gadgets_hash{$exploit_hash{$combo_str}{$regs[2]}{GADGET}}, $gadgets_hash{$exploit_hash{$combo_str}{$regs[3]}{GADGET}});
        my $stddev = stddev($vals);

        printf("%-20s\t%-10s|%-6d\t%-5s\t%-10s|%-6d\t%-5s\t%-10s|%-6d\t%-5s\t%-10s|%-6d\t%-5s\t%-20s\t%-5f\n",
               $combo_str,
               $exploit_hash{$combo_str}{$regs[0]}{GADGET}, $gadgets_hash{$exploit_hash{$combo_str}{$regs[0]}{GADGET}}, $exploit_hash{$combo_str}{$regs[0]}{RET_ADDR},
               $exploit_hash{$combo_str}{$regs[1]}{GADGET}, $gadgets_hash{$exploit_hash{$combo_str}{$regs[1]}{GADGET}}, $exploit_hash{$combo_str}{$regs[1]}{RET_ADDR},
               $exploit_hash{$combo_str}{$regs[2]}{GADGET}, $gadgets_hash{$exploit_hash{$combo_str}{$regs[2]}{GADGET}}, $exploit_hash{$combo_str}{$regs[2]}{RET_ADDR},
               $exploit_hash{$combo_str}{$regs[3]}{GADGET}, $gadgets_hash{$exploit_hash{$combo_str}{$regs[3]}{GADGET}}, $exploit_hash{$combo_str}{$regs[3]}{RET_ADDR},
               $exploit_hash{$combo_str}{TIME},
               $stddev);

        if ($least_time_to_exploit == 0.0 || $exploit_hash{$combo_str}{TIME} < $least_time_to_exploit){
            $least_time_to_exploit = $exploit_hash{$combo_str}{TIME};
            $best_combo = $combo_str;
        }

        if (least_stddev == 0.0 || $stddev < $least_stddev){
            $least_stddev = $stddev;
        }
    }

    print "LEAST TIME TO EXPLOIT: $least_time_to_exploit for combination $best_combo\n";
    print "LEAST STDDEV: $least_stddev\n";

}

main();
