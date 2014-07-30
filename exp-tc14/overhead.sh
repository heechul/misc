#!/bin/bash
#
# measure overhead

. ./functions

test_overhead_cpuhog()
{
    set_cpus "1 1 1 1"
    ./cpuhog -c 1 &
    ./cpuhog -c 2 &
    ./cpuhog -c 3 &

    for period in 100 250 500 1000 2500; do
	PERIOD_US=$period do_init_mb "10000 10000 10000 10000" 0 0
	time ./cpuhog -c 0 -i 2000000000 -o fifo
	rmmod memguard
    done

    time ./cpuhog -c 0 -i 2000000000 -o fifo

    killall -2 cpuhog
}

test_overhead_bandwidth_cpuhog()
{
    set_cpus "1 1 1 1"
    ./cpuhog -c 1 &
    ./cpuhog -c 2 &
    ./cpuhog -c 3 &

    for period in 100 250 500 1000 2500; do
	PERIOD_US=$period do_init_mb "100 10000 10000 10000" 0 0
	./bandwidth -t 1000 -i 2000 -c 0 | grep elapsed
	rmmod memguard
    done

    ./bandwidth -t 1000 -i 2000 -c 0 | grep elapsed

    killall -2 cpuhog

}


test_overhead_latency()
{
    set_cpus "1 1 1 1"
    ./latency -i 10000 -c 1 &
    ./latency -i 10000 -c 2 &
    ./latency -i 10000 -c 3 &

    for period in 100 250 500 1000 2500; do
#	for period in 2500 2500 2500 2500 2500; do
        # PERIOD_US=$period do_init_mb "10000 10000 10000 10000" 0 0
	PERIOD_US=$period do_init_mb "100 100 100 100" 0 0
	log_echo "MG(P=$period us)"
	./latency -i 100 -c 0 | grep average >> $outputfile
	rmmod memguard
    done

    log_echo "NoMG"
    ./latency -i 100 -c 0 | grep average >> $outputfile
    killall -9 latency
}



test_overhead_latency
# test_overhead_bandwidth_cpuhog
tail -n 16 log.txt | grep average | awk '{ print $2 }'