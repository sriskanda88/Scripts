gadgets_file=$1
reg_to_fill=$2

base="/home/skanda/proj/bintrans/run/x86/libquantum"
out="/home/skanda/scratch/psr_brute_force/x86/libquantum"

for gadget in `cat $gadgets_file`; do
    echo "Executing gadget: $gadget"
    timeout 5 $base/psr $base/libquantum $gadget $reg_to_fill >> $out/libquantum.$reg_to_fill.out
done
