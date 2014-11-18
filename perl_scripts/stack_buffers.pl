#!/usr/bin/perl

use Cwd 'abs_path';
use constant{BUFFER=>"buffer", SIZE=>"size", RET_DIST=>"ret_dist", OFFSET=>"offset",
    TOTAL_BUFF_COUNT=>"total_buff_count", TOTAL_BUFF_SIZE=>"total_buff_size",
    AVG_BUFF_SIZE=>"avg_buff_size" };

my $stack_slots_tag = "Fixed Stack Slots: ";
my $callee_saves_tag = "Callee Save: ";
my $name_tag = "Name: ";

my %function_buffers;

sub trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };

sub main(){
    my $filename;

    if (@ARGV == 0){
        print "Usage : ./stack_buffers.pl <lra file>\n";
        exit();
    }

    $filename = $ARGV[0];
    analyze_stack_slots(abs_path($filename));
}

sub analyze_stack_slots(){
    my $filename = $_[0];
    my $curr_buff, $prev_buff;
    my $rec = 0;
    my $ret, $fp;

    my $line, $prev_line;
    my $func_name = "build_";

    open FL, "<$filename" or die "Unable to open lra file for reading";

    while($line = <FL>){
        while (!eof(FL) && $line !~ m/$name_tag(?!.*build_)/){
            $line = <FL>;
        }
        break if eof(FL);

        chomp($line);
        $func_name = (split(/: /, $line))[1];
        print "------------------------------------------------------------\n";
        print "Function : $func_name\n";

        while(!eof(FL) && $line !~ m/$callee_saves_tag/){
            $line = <FL>;
        }
        break if eof(FL);

        $ret = ($line =~ m/\[SP\+([0-9]+)\]\:\%RET/g)[0];
        $fp = ($line =~ m/\[SP\+([0-9]+)\]\:\%FP/g)[0];
        print "RET : $ret\n";
        print "FP : $fp\n";
        print "\n";

        while(!eof(FL) && $line !~ m/$stack_slots_tag/){
            $line = <FL>;
        }
        break if eof(FL);

        my %slots;
        my $tmp_count = 0;

        while($line =~ /\[SP\+([0-9]+)\]\:([a-zA-Z0-9 \.]+)/g){
            my $tmp_name = $2;
            if ($tmp_name eq " "){
                $tmp_name = "noname.$tmp_count";
                $tmp_count++;
            }

            $tmp_name = trim($tmp_name);
            if (exists($slots{$tmp_name})){
                $tmp_name = "$tmp_name.dup";
            }
            $slots{$tmp_name} = $1;
        }

        if (!%slots){
            next;
        }

        my $curr_buff_name;
        my $curr_buff_offset = 0;
        my $prev_buff_offset = $fp;
        $function_buffers{$func_name}{TOTAL_BUFF_COUNT} = 0;
        $function_buffers{$func_name}{TOTAL_BUFF_SIZE} = 0;

        foreach my $slot (sort { $slots{$b} <=> $slots{$a} } keys %slots){
            $curr_buff_name = $slot;
            $curr_buff_offset = $slots{$slot};

            #print("$slot -> $slots{$slot}\n");

            if (($prev_buff_offset - $curr_buff_offset) > 8 && $curr_buff_offset < $fp){

                #printf("%s - %s = %s\n", $prev_buff_offset, $curr_buff_offset, $prev_buff_offset - $curr_buff_offset);
                $function_buffers{$func_name}{$curr_buff_name}{BUFFER} = $curr_buff_name;
                $function_buffers{$func_name}{$curr_buff_name}{OFFSET} = $curr_buff_offset;
                $function_buffers{$func_name}{$curr_buff_name}{SIZE} = $prev_buff_offset - $curr_buff_offset;
                $function_buffers{$func_name}{$curr_buff_name}{RET_DIST} = $ret - $curr_buff_offset;

                $function_buffers{$func_name}{TOTAL_BUFF_COUNT} += 1;
                $function_buffers{$func_name}{TOTAL_BUFF_SIZE} += $prev_buff_offset - $curr_buff_offset;

                print "BUFF NAME : $function_buffers{$func_name}{$curr_buff_name}{BUFFER}\n";
                print "BUFF OFFSET : $function_buffers{$func_name}{$curr_buff_name}{OFFSET}\n";
                print "BUFF SIZE : $function_buffers{$func_name}{$curr_buff_name}{SIZE}\n";
                print "RET DIST : $function_buffers{$func_name}{$curr_buff_name}{RET_DIST}\n";
                print "\n";
            }

            $prev_buff_offset = $curr_buff_offset;
        }

        if ($function_buffers{$func_name}{TOTAL_BUFF_COUNT} > 0){
            $function_buffers{$func_name}{AVG_BUFF_SIZE} = $function_buffers{$func_name}{TOTAL_BUFF_SIZE} / $function_buffers{$func_name}{TOTAL_BUFF_COUNT};
            print "TOTAL BUFF SIZE : $function_buffers{$func_name}{TOTAL_BUFF_SIZE}\n";
            print "AVG BUFF SIZE : $function_buffers{$func_name}{AVG_BUFF_SIZE}\n";
        }
    }

    close(FP);

    my $func_buff_sum = 0;
    my $func_count = 0;

    foreach my $func (keys %function_buffers){
        $func_count++;
        $func_buff_sum += $function_buffers{$func}{TOTAL_BUFF_SIZE};
    }

    print "\n";
    printf("Total Functions : %d\n", $func_count);
    printf("Average Buff Size per Function: %d\n", $func_buff_sum/$func_count);
}

main();
