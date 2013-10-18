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

echo 2 > /sys/kernel/debug/color_page_alloc/debug_level
echo $$ > /sys/fs/cgroup/tasks

log_echo "SPEC vs. 3xlbm"

echo $$ > /sys/fs/cgroup/tasks
log_echo 'corun-buddy'
echo 99 > /sys/kernel/debug/color_page_alloc/debug_level
for cpu in 1 2 3; do
    ./profile-corun-lbm.sh $cpu &
done
for i in `seq 1 $repeat`; do
    ./profile.sh 0
done

echo done > DONE
kill_spec
sleep 1
exit

log_echo '4B-diffbank-LO-w/lbm'
for cpu in 1 2 3; do
    echo 0-3 > /sys/fs/cgroup/core$cpu/phdusa.dram_rank
    echo $cpu > /sys/fs/cgroup/core$cpu/phdusa.dram_bank
    echo $$ > /sys/fs/cgroup/core$cpu/tasks
    echo 2 > /sys/kernel/debug/color_page_alloc/debug_level

    ./profile-corun-lbm.sh $cpu &
done

echo 0-3 > /sys/fs/cgroup/spec2006/phdusa.dram_rank
echo 0 > /sys/fs/cgroup/spec2006/phdusa.dram_bank
echo $$ > /sys/fs/cgroup/spec2006/tasks
for i in `seq 1 $repeat`; do
    ./profile.sh 0
done

echo done > DONE
kill_spec
sleep 1

log_echo '4B-diffbank-HI-w/lbm'
for cpu in 1 2 3; do
    echo $cpu > /sys/fs/cgroup/core$cpu/phdusa.dram_rank
    echo 0-3 > /sys/fs/cgroup/core$cpu/phdusa.dram_bank
    echo $$ > /sys/fs/cgroup/core$cpu/tasks
    echo 2 > /sys/kernel/debug/color_page_alloc/debug_level
    ./profile-corun-lbm.sh $cpu &
done

echo 0 > /sys/fs/cgroup/spec2006/phdusa.dram_rank
echo 0-3 > /sys/fs/cgroup/spec2006/phdusa.dram_bank
echo $$ > /sys/fs/cgroup/spec2006/tasks
for i in `seq 1 $repeat`; do
    ./profile.sh 0
done

echo done > DONE
kill_spec
sleep 1


chown heechul.heechul profile.txt
