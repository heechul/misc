#!/bin/bash

. ./functions
. ~/.bash_profile

outputfile=profile.txt
repeat=1

echo done > DONE
kill_spec
sleep 1
rm -f DONE

[ -d "/sys/fs/cgroup/core1" ] || error "core1 cgroup does not exist"

echo 2 > /sys/kernel/debug/palloc/debug_level
echo 0 > /sys/kernel/debug/palloc/alloc_balance
echo $$ > /sys/fs/cgroup/tasks

log_echo "SPEC vs. 3xlbm"

log_echo '4B-diffbank-LO-w/lbm'
cpu=1
for bins in "4-7" "8-11" "12-15"; do
    echo $bins > /sys/fs/cgroup/core$cpu/palloc.bins
    echo $$ > /sys/fs/cgroup/core$cpu/tasks
    echo 2 > /sys/kernel/debug/palloc/debug_level
    ./profile-corun-lbm.sh $cpu &
    cpu=`expr $cpu + 1`
done

echo "0-3" > /sys/fs/cgroup/spec2006/palloc.bins
echo $$ > /sys/fs/cgroup/spec2006/tasks
for i in `seq 1 $repeat`; do
    ./profile.sh 0
done

echo done > DONE
kill_spec
sleep 1

log_echo '4B-diffbank-HI-w/lbm'
cpu=1
for bins in "1,5,9,13" "2,6,10,14" "3,7,11,15"; do
    echo $bins > /sys/fs/cgroup/core$cpu/phlloc.bins
    echo $$ > /sys/fs/cgroup/core$cpu/tasks
    echo 2 > /sys/kernel/debug/palloc/debug_level
    ./profile-corun-lbm.sh $cpu &
    cpu=`expr $cpu + 1`
done

echo 0,4,8,12 > /sys/fs/cgroup/spec2006/palloc.bins
echo $$ > /sys/fs/cgroup/spec2006/tasks
for i in `seq 1 $repeat`; do
    ./profile.sh 0
done

echo done > DONE
kill_spec
sleep 1


echo $$ > /sys/fs/cgroup/tasks
log_echo 'corun-buddy'
echo 99 > /sys/kernel/debug/palloc/debug_level
for cpu in 1 2 3; do
    ./profile-corun-lbm.sh $cpu &
done
for i in `seq 1 $repeat`; do
    ./profile.sh 0
done

echo done > DONE
kill_spec
sleep 1

chown heechul.heechul profile.txt
