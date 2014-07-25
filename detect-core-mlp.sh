#!/bin/bash

curbanks=""
ncore=1
for bank in `seq 0 15`; do
    [ "$curbanks" == "" ] && curbanks=$bank || curbanks="$curbanks,$bank"
    # echo $curbanks
    bw=`./mlp -b $curbanks -i 1000000 | grep bandwidth | awk '{ print $2 }'`
    echo $ncore $bw
    ncore=`expr $ncore + 1`
done