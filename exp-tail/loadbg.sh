#!/bin/bash

cd `dirname $0`
. ./functions

mincpu=$2
maxcpu=$3
bencha=$4
benchb=$5
stime=$6

# run spec benchmarks (high and low intensive)

echo $mincpu $maxcpu $bencha $benchb 

for cpu in `seq $mincpu $maxcpu`; do
    # run_bench 462.libquantum $cpu &
    # run_bench 465.tonto $cpu &
    run_bench $bencha $cpu &
    run_bench $benchb $cpu &
done

sleep $stime

kill_spec 

for cpu in `seq $mincpu $maxcpu`; do
    for b in $bencha $benchb; do 
        f="C$cpu.$b.perf"
        X=`parse_perf_log $f`
        echo $f $X
    done
done
