#!/bin/sh

bm=$1

~/proj/scripts/perl_scripts/psr_brute_forcer.pl ~/scratch/psr_brute_force/x86/$bm/"$bm".gadgets ~/scratch/psr_brute_force/x86/$bm/"$bm".out > ~/scratch/psr_brute_force/x86/$bm/"$bm".results
