#!/bin/bash

. functions
init_system
init_log test-latency.txt

#WSIZES="16 64 512 32768"
#NCPUS=7

WSIZES="32768"
NCPUS=3

load_on()
{
    cores="$1"
    size=$2
    accesstype=$3

    killall -9 bandwidth latency

    for c in $cores; do
	./latency -c $c -m $size $accesstype -i 10000000 &
    done > /dev/null

    sleep 10
    echo done
}

run_on()
{
    core=$1
    size=$2
    repeat=$3
    accesstype=$4
    LINE=`./latency -c $core -m $size -i $repeat $accesstype | \
	grep average`
    echo_log $LINE
    killall -9 bandwidth latency
}


exp1()
{
    echo_log "Exp1: unicore sequential"
    for wsize in $WSIZES; do
	run_on 0 $wsize 100 "-s"
    done
}

exp2()
{
    echo_log "Exp2: unicore permuted"
    for wsize in $WSIZES; do
	run_on 0 $wsize 100
    done
}

exp3()
{
    echo_log "Exp5: multicore perm-perm(read)"

    for wsize in $WSIZES; do
	echo_log "WS=$wsize kb"
	echo_log "2core (diff cache)"
	load_on "2" $wsize; run_on 0 $wsize 100

	echo_log "2core (same cache)"
	load_on "1" $wsize; run_on 0 $wsize 100

	echo_log "4core"
	load_on "1 2 3" $wsize; run_on 0 $wsize 100
    done
}

exp1
exp2
exp3

show_log 10
