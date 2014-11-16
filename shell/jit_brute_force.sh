bm=$1
value_to_fill=$2

base="/tmp/$bm"
out="/home/sshamasu/rop/scratch/jit_brute_force/x86/$bm"

for gadget in `cat $base/$bm.jit_gadgets`; do
    echo "Executing gadget: $gadget"
    timeout 60 $base/psr -b $base/$bm -m $base/m5out/cpt_with_psr/remapped_$bm -g $gadget -v $value_to_fill >> $out/$bm.$value_to_fill.out
done
