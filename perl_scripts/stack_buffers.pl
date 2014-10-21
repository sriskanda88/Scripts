#!/usr/bin/perl

use Cwd 'abs_path';

my $stack_slots_tag = "Fixed Stack Slots";
my $callee_saves_tag = "Callee Save";
my $name_tag = "Name";
my @buff_sizes;
my @ret_dist;

sub main(){
    my $filename;

    if (@ARGV == 0){
        print "Usage : ./stack_buffers.pl <lra file>\n";
        exit();
    }

    $filename = $ARGV[0];
    my $avg_stack_buff_size = analyze_stack_slots(abs_path($filename));

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

        if ($line =~ m/$name_tag/){
            $func_name = (split(/: /, $line))[1];
        }

        if ($line eq "\n"){
            $func_name = "build_";
            $rec = 0;
            next;
        }

        if ($rec == 0 && $func_name !~ m/build_/){
            $rec = 1;
        }

        if ($rec != 1){
            next;
        }

        if ($line =~ m/$name_tag/  && $func_name !~ m/build_/){
            print "$func_name";
        }

        chomp($line);

        if ($line =~ m/$callee_saves_tag/){
            $ret = ($line =~ m/\[SP\+([0-9]+)\]\:\%RET/g)[0];
            $fp = ($line =~ m/\[SP\+([0-9]+)\]\:\%FP/g)[0];
            print "RET : $ret\n";
            print "FP : $fp\n";
        }

        if ($line =~ m/$stack_slots_tag/){

            @slots = $line =~ m/\[SP\+([0-9]+)\]/g;
            if (@slots == 0){
                print "\n";
                next;
            }

            $curr_buff = 0;
            $prev_buff = 0;

            foreach $slot (@slots){
                $curr_buff = $slot;
                if ($prev_buff - $curr_buff > 8 && $curr_buff < $fp){
                    push(@buff_sizes, $prev_buff - $curr_buff);
                    push(@ret_dist, $ret - $curr_buff);
                    printf ("BUFF ADDR : %d\n",$curr_buff);
                    printf ("BUFF SIZE : %d\n",$prev_buff - $curr_buff);
                    printf ("RET DIST : %d\n",$ret - $curr_buff);
                }

                if($prev_buff = 0 && $fp - $curr_buff > 8 ){
                    push(@buff_sizes, $fp - $curr_buff);
                    push(@ret_dist, $ret - $curr_buff);
                    printf ("BUFF ADDR : %d\n",$curr_buff);
                    printf ("BUFF SIZE : %d\n",$fp - $curr_buff);
                    printf ("RET DIST : %d\n",$ret - $curr_buff);
                }

                $prev_buff = $curr_buff;
            }
            print "\n";
        }
    }

    my $buff_sum, $dist_sum = 0;
    my $buff_count = scalar(@buff_sizes);
    my $dist_count = scalar(@ret_dist);

    foreach $buff (@buff_sizes){
        $buff_sum += $buff;
    }
    foreach $ret_dist (@ret_dist){
        $dist_sum += $ret_dist;
    }
    print "\n";
    print "Total Buff Size : $buff_sum\n";
    print "Count : $buff_count\n";
    print "Total Ret Dist : $dist_sum\n";
    print "Count : $dist_count\n";

    my $avg_buff_size = $buff_sum/$buff_count;
    my $avg_ret_dist = $dist_sum/$dist_count;
    print "Avg stack buffer size : $avg_buff_size\n";
    print "Avg distance to ret : $avg_ret_dist\n";

    return $buff_sum/$buff_count;
}

main();
