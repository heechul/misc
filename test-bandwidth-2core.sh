#!/bin/bash

LLC_SIZE=1000
BENCH_SIZE=200

LOG="test-bandwidth-2core.txt"
log()
{
	echo $*
	echo $* >> $LOG
}

run_cachebuster()
{
    # ./bandwidth -m $LLC_SIZE -c 1 -t 100 > /dev/null &
    ./latency -m $LLC_SIZE -c 0 -i 100000 | grep average > /dev/null &
}

run_bench()
{
    # ./bandwidth -m $BENCH_SIZE -c 0 -t 1 | grep average
    ./latency -m $BENCH_SIZE -c 0 -i 10000 | grep average
}


log "`uname -a`"
log "`date`"

out1=`run_bench`
log "solo   ${BENCH_SIZE}k $out1"

run_cachebuster
out1=`run_bench`
log "co-run ${BENCH_SIZE}k $out1"
killall -9 bandwidth latency
