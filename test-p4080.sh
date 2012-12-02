#!/bin/bash

#WSIZES="16 64 512 32768"
#NCPUS=7

WSIZES="16 512 32768"
NCPUS=3

load()
{
	corun=$1
	size=$2
	accesstype=$3
	killall -9 latency bandwidth

	for c in `seq 1 $corun`; do
#		./latency $size $accesstype 10000000 $c &
		./bandwidth $size $accesstype 10000000 &
	done > /dev/null
	# sleep 1
}

run()
{
	size=$1
	accesstype=$2
	repeat=$3
	./latency $size $accesstype $repeat 0 | grep average | awk '{ print $2 }'
}


exp1()
{
echo "Exp1: unicore sequential"
for wsize in $WSIZES; do
	run $wsize 1 100
done
}

exp2()
{
echo "Exp2: unicore permuted"
for wsize in $WSIZES; do
	run $wsize 0 100
done
}

exp3()
{
echo "Exp3: multicore seq-seq(read)"

for wsize in $WSIZES; do
	echo "WS=$wsize kb"
	killall -9 latency bandwidth
	run $wsize 1 100
	for ncpu in `seq 1 $NCPUS`; do
		load $ncpu $wsize read; run $wsize 1 100
	done
done
killall -9 latency bandwidth
}

exp4()
{
echo "Exp4: multicore seq-seq(write)"

for wsize in $WSIZES; do
	echo "WS=$wsize kb"
	run $wsize 0 100
	for ncpu in `seq 1 $NCPUS`; do
		load $ncpu $wsize write; run $wsize 1 100
	done
done
killall -9 latency bandwidth
}

exp5()
{
echo "Exp5: multicore perm-seq(read)"

for wsize in $WSIZES; do
	echo "WS=$wsize kb"
	run $wsize 1 100
	for ncpu in `seq 1 $NCPUS`; do
		load $ncpu $wsize read; run $wsize 0 100
	done
done
killall -9 latency bandwidth
}

exp6()
{
echo "Exp6: multicore perm-seq(write)"
for wsize in $WSIZES; do
	echo "WS=$wsize kb"
	run $wsize 0 100
	for ncpu in `seq 1 $NCPUS`; do
		load $ncpu $wsize write; run $wsize 0 100
	done
done
killall -9 latency bandwidth
}

exp1
exp2
exp3 
exp4 
exp5 
exp6 

killall -9 latency bandwidth
exit
