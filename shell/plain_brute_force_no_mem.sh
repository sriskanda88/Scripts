bm=$1
value_to_fill=$2

base="/tmp/$bm""_no_mem"
out="/home/sshamasu/rop/scratch/plain_brute_force_no_mem/x86/$bm"

for gadget in `cat $base/$bm.gadgets`; do
    echo "Executing gadget: $gadget"
    timeout 60 $base/psr --no-psr --no-physmem -b $base/$bm -g $gadget -v $value_to_fill >> $out/$bm.$value_to_fill.out
done
