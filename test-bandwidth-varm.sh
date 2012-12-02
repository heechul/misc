#!/bin/bash

LOG="test-bandwidth-varm.txt"
log()
{
	echo $*
	echo $* >> $LOG
}

for m in 30 120 250 500 1000 1500 2000; do
	out=`./bandwidth -m $m -t 1 | grep average`
	log "${m}k $out"
done
