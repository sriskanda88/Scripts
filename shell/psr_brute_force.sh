bm=$1
value_to_fill=$2

base="/home/skanda/proj/bintrans/run/x86/$bm"
out="/home/skanda/scratch/psr_brute_force/x86/$bm"

for gadget in `cat $base/$bm.gadgets`; do
    echo "Executing gadget: $gadget"
    timeout 60 $base/psr -b $base/$bm -g $gadget -v $value_to_fill >> $out/$bm.$value_to_fill.out
done
