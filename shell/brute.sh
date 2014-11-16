#!/bin/sh

bm=$1

./psr -b $bm -v 0x1234abcd -g $bm.pending_gadgets -x out_1234abcd > ./log_1234abcd
#./psr -b $bm -v 0x0 -g $bm.gadgets -x out_0 > ./log_0
#./psr -b $bm -v 0xb -g $bm.gadgets -x out_b > ./log_b

#./psr -b $bm -v 0x1234abcd -g $bm.gadgets -x out_1234abcd_plain --no-psr  > ./log_1234abcd_plain

