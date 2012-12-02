#!/bin/bash

LOG="test-bandwidth-2core.txt"
log()
{
	echo $*
	echo $* >> $LOG
}

m=1000
out1=`./bandwidth -m $m -c 0 -t 1 | grep average`
log "solo   ${m}k $out1"


./bandwidth -m $m -c 1 -t 100 > /dev/null &
out1=`./bandwidth -m $m -c 0 -t 1 | grep average`
log "co-run ${m}k $out1"
killall -9 bandwidth
