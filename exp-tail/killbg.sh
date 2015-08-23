#!/bin/bash

cd `dirname $0`
. ./functions

kill_spec

for f in C*.perf; do
    X=`parse_perf_log $f`
    echo $f $X
done
