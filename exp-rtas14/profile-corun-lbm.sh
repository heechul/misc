#!/bin/bash

[ -z "$1" ] && targetcpu=1 || targetcpu=$1

. functions 

# for bench in $spec2006_xeon_all; do
# done
[ -f "DONE" ] && rm -f DONE

bench=470.lbm
while true; do
    run_bench $bench $targetcpu
    [ -f "DONE" ] && break
done
echo done
