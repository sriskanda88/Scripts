value_to_fill=$1

bm="mcf"
base="/tmp/$bm"
out="/home/sshamasu/rop/scratch/psr_brute_force/x86/$bm"

for gadget in `cat $base/$bm.gadgets`; do
    echo "Executing gadget: $gadget"
    timeout 60 $base/psr -b $base/$bm -g $gadget -v $value_to_fill >> $out/$bm.$value_to_fill.out
done
