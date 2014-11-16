bm=$1
value_to_fill=$2

base="/tmp/$bm""_no_mem"
out="/home/sshamasu/rop/scratch/psr_brute_force_no_mem/x86/$bm"

for gadget in `cat $base/$bm.gadgets`; do
    echo "Executing gadget: $gadget"
    timeout 60 $base/psr -b $base/$bm --no-physmem -g $gadget -v $value_to_fill >> $out/$bm.$value_to_fill.out
done
