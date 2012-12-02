#!/bin/bash

. functions

LOG="test-bandwidth.txt"
init_system
init_log $LOG

log()
{
    echo $*
    echo $* >> $LOG
}

# cache aware version
load_on()
{
    cores=$1
    for c in $cores; do
	./bandwidth -c $c -i 100000 >& /dev/null &
    done > /dev/null
}

run_on()
{
    core=$1
    LINE=`./bandwidth -c $core -i 4000 | grep average`
    log $LINE
    killall -9 bandwidth
}

log "one core"
run_on 0

log "two cores (same cache)"
load_on 1
run_on 0

log "two cores (separate cache)"
load_on 2
run_on 0

log "four cores"
load_on "0 1 3"
run_on 2