#!/bin/bash

[ -z "$1" ] && targetcpu=1 || targetcpu=$1

. functions 
. ~/.bash_profile

# done
# for bench in 462.libquantum; do

for bench in $spec2006_xeon_rta13; do
    run_bench $bench $targetcpu
    [ -f "DONE" ] && break
done
rm -f DONE