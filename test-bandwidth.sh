#!/bin/bash

. functions

LOG="test-bandwidth.txt"
init_system
init_log $LOG

WSIZES="32768"
NCPUS=3

# cache aware version
load_on()
{
    cores=$1
    for c in $cores; do
	./bandwidth -m $WSIZES -c $c -i 100000 >& /dev/null &
    done > /dev/null
}

run_on()
{
    core=$1
    LINE=`./bandwidth -m $WSIZES -c $core -i 4000 | grep average`
    echo_log $LINE
    killall -9 bandwidth
}

echo_log "one core"
run_on 0

echo_log "two cores (same cache)"
load_on 1
run_on 0

echo_log "two cores (separate cache)"
load_on 2
run_on 0

echo_log "four cores"
load_on "0 1 3"
run_on 2