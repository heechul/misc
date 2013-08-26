#!/bin/bash 

MSIZE=16384

wait_key()
{
	echo "Press any key"
	read buf
}

load()
{
	cpu=$1
	./latency -m $MSIZE -i 10000000000 -c $cpu
}

killall latency

wait_key
load 1 &
pidof latency

wait_key
load 2 &
pidof latency

wait_key
load 3 &
pidof latency

wait_key
killall latency
