#!/usr/bin/perl

open FL, "</tmp/file2";

while(<FL>){
	printf("%d\n", hex($_));
}

close FL;
