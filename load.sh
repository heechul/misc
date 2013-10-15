#!/bin/bash 

#MSIZE=16384
# MSIZE=65536
#LOAD=latency
LOAD=bandwidth

MSIZE=$1

if [ -z "$MSIZE" ]; then
	echo "Usage: $0 <size>"
	exit 1
fi  
wait_key()
{
	echo "Press any key"
	read buf
}

load()
{
	cpu=$1

#	echo $$ > /sys/fs/cgroup/core$cpu/task

	if [ "$LOAD" = "latency" ]; then 
		./latency -m $MSIZE -i 10000000000 -c $cpu
	elif [ "$LOAD" = "bandwidth" ]; then
		./bandwidth -m $MSIZE -a write -t 10000000000 -c $cpu 
	fi
}

killall latency bandfwidth

wait_key
load 1 &
pidof $LOAD

wait_key
load 2 &
pidof $LOAD

wait_key
load 3 &
pidof $LOAD

wait_key
killall latency bandwidth
