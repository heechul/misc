#!/bin/bash 
wait_key()
{
	echo "Press any key"
	read
}

killall latency

wait_key
./latency -i 10000000000 -c 1 &
pidof latency

wait_key
./latency -i 10000000000 -c 2 &
pidof latency

wait_key
./latency -i 10000000000 -c 3 &
pidof latency

wait_key
killall latency
