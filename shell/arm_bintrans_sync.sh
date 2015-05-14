#!/bin/sh
echo "Syncing src from skanda to matricks"
rsync -avz ~/proj/bintrans_orig/src sshamasu@matricks.ucsd.edu:~/bintrans_orig/

echo "Making on matricks"
ssh sshamasu@matricks.ucsd.edu 'cd bintrans_orig; make isa=arm mode=test'

echo "Syncing binary from matricks to skanda"
rsync -avz sshamasu@matricks.ucsd.edu:~/bintrans_orig/test/arm/psr ~/proj/bintrans_orig/test/arm/
