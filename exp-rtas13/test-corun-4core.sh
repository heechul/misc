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


log_echo "SPEC vs. 3xSPEC"

log_echo '4B-diffbank-LO-w/spec'
for i in `seq 1 $repeat`; do
    for cpu in 1 2 3; do
	echo $cpu > /sys/fs/cgroup/core$cpu/phdusa.dram_bank
	echo 0-3 > /sys/fs/cgroup/core$cpu/phdusa.dram_rank
	echo $$  > /sys/fs/cgroup/core$cpu/tasks
	echo 2 > /sys/kernel/debug/color_page_alloc/debug_level
	./profile-corun.sh $cpu &
    done
    
    echo 0 > /sys/fs/cgroup/spec2006/phdusa.dram_bank
    echo 0-3 > /sys/fs/cgroup/spec2006/phdusa.dram_rank
    echo $$ > /sys/fs/cgroup/spec2006/tasks
    ./profile.sh 0
done
sync
sleep 3

log_echo '4B-diffbank-HI-w/spec'
for i in `seq 1 $repeat`; do
    for cpu in 1 2 3; do
	echo $cpu > /sys/fs/cgroup/core$cpu/phdusa.dram_rank
	echo 0-3 > /sys/fs/cgroup/core$cpu/phdusa.dram_bank
	echo $$ > /sys/fs/cgroup/core$cpu/tasks
	echo 2 > /sys/kernel/debug/color_page_alloc/debug_level
	./profile-corun.sh $cpu &
    done
    
    echo 0 > /sys/fs/cgroup/spec2006/phdusa.dram_rank
    echo 0-3 > /sys/fs/cgroup/spec2006/phdusa.dram_bank
    echo $$ > /sys/fs/cgroup/spec2006/tasks
    ./profile.sh 0
done

sync
sleep 3
exit


echo 99 > /sys/kernel/debug/color_page_alloc/debug_level
log_echo 'corun-buddy'
for i in `seq 1 $repeat`; do
    for cpu in 1 2 3; do
	./profile-corun.sh $cpu &
    done
    ./profile.sh 0
done



