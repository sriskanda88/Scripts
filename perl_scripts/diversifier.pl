#!/usr/bin/perl
no warnings;

use Data::Dumper;
use constant{REG_LIST=>"reg_list", CLOBBER=>"clobber", STACK_MOD=>"stack_mod", RET_ADDR=>"ret_addr", FRAME_SIZE=>"frame_size"};
use constant(DUMP=>0);

my $jittable_gadgets_file;
my $all_gadgets_file;

my @jittable_gadgets_list;
my %jittable_gadgets_hash;
my %diversified_gadgets_hash;

my %reg_hash = ("eax" => 0, "ecx" => 1, "edx" => 2, "ebx" => 3, "ebp" => 5, "esi" => 6, "edi" => 7);

my %reg_gadgets_hash;
my %result_hash;

sub main(){
    if ($#ARGV < 1){
        die "Usage: diversifier.pl <jittable_gadgets_file> <all_gadgets_file>\n";
    }

    $jittable_gadgets_file = $ARGV[0];
    $all_gadgets_file = $ARGV[1];

    #read input files
    read_data();

    #diversify
    gen_diversified_gadgets();

    #analyze this
    analyze();

    #print results
    print Dumper(\%result_hash);
}

sub analyze(){
    # different gadget sizes to try
    my @populable_regs = keys %reg_gadgets_hash;
    my $num_populable_regs = scalar @populable_regs;
    for (my $size = 3; $size <=$num_populable_regs; $size++){
        %temp_regs = %reg_hash;
        my @regs_to_fill = ();

        while($#regs_to_fill != ($size-1)){
            my $newreg = (keys %temp_regs)[rand keys %temp_regs];
            delete $temp_regs{$newreg};

            push(@regs_to_fill, $newreg) if (exists($reg_gadgets_hash{$newreg}));
        }

        print "REG combination: @regs_to_fill\n";

        my $count = 0;
        my $keep_trying = 1;
        while($keep_trying){
            $count++;

            my $success_regs = 0;
            for my $reg (@regs_to_fill){
                #print "Reg to fill: $reg\n";

                #print "$#{$reg_gadgets_hash{$reg}}\n";
                next if ($#{$reg_gadgets_hash{$reg}} == -1);

                my $gadget = @{$reg_gadgets_hash{$reg}}[int(rand ($#{$reg_gadgets_hash{$reg}} + 1))];
                #print "Gadget picked: $gadget\n";

                my @gadget_populates = (int(rand(2)) == 0)? $jittable_gadgets_hash{$gadget}{REG_LIST} : $diversified_gadgets_hash{$gadget}{REG_LIST};
                #print Dumper(@gadget_populates);

                $success_regs++ if ($reg ~~ @gadget_populates);
                #print "$success_regs\n";
            }

            $keep_trying = 0 if($success_regs == $size);
        }

        $result_hash{$size} = $count;
    }
}

sub gen_diversified_gadgets(){
    for my $gadget (keys %jittable_gadgets_hash){
        %temp_regs = %reg_hash;
        for my $reg (@{$jittable_gadgets_hash{$gadget}{REG_LIST}}){
            delete $temp_regs{$reg};
        }
        $diversified_gadgets_hash{$gadget}{REG_LIST} = ();
        for my $reg (@{$jittable_gadgets_hash{$gadget}{REG_LIST}}){
            my $newreg = (keys %temp_regs)[rand keys %temp_regs];
            push(@{$diversified_gadgets_hash{$gadget}{REG_LIST}}, $newreg);
            delete $temp_regs{$newreg};
        }
    }

    print Dumper(%diversified_gadgets_hash) if DUMP;
}

sub read_data(){
    open(FL, "<$jittable_gadgets_file") or die "Unable to open jittable gadgets file\n";
    while(my $gadget = <FL>){
        # sanitize input
        chomp($gadget);
        $gadget =~ s/://g;

        if ($gadget !~ m/^0x/){
            $gadget = "0x".$gadget;
        }

        push(@jittable_gadgets_list, $gadget);
    }
    close(FL);

    open(FL, "<$all_gadgets_file") or die "Unable to open all gadgets file\n";
    while(my $line = <FL>){
        chomp($line);
        my ($gadget, $reg) = (split(/\|/, $line))[0..1];
        if ($gadget ~~ @jittable_gadgets_list){
            if (!exists($jittable_gadgets_hash{$gadget})){
                $jittable_gadgets_hash{$gadget}{REG_LIST} = ();
            }
            push(@{$jittable_gadgets_hash{$gadget}{REG_LIST}}, $reg);

            ($jittable_gadgets_hash{$gadget}{CLOBBER}, $jittable_gadgets_hash{$gadget}{STACK_MOD},
                $jittable_gadgets_hash{$gadget}{RET_ADDR}, $jittable_gadgets_hash{$gadget}{FRAME_SIZE}) = (split(/\|/, $line))[3..6];

            if (!exists($reg_gadgets_hash{$reg})){
                $reg_gadgets_hash{$reg} = ();
            }
            push(@{$reg_gadgets_hash{$reg}}, $gadget);
        }
    }
    close(FL);

    print Dumper(%jittable_gadgets_hash) if DUMP;
    print Dumper(%reg_gadgets_hash) if DUMP;
}

main();
