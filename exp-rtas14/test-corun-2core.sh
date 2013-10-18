#!/bin/bash

. functions
. ~/.bash_profile

outputfile=profile.txt
repeat=1

echo done > DONE
kill_spec
sleep 1
rm -f DONE

log_echo '8B-diffbank-HI-w/spec'
for i in `seq 1 $repeat`; do
    echo 0,1 > /sys/fs/cgroup/corun_diffbank/phdusa.dram_rank
    echo 0-3 > /sys/fs/cgroup/corun_diffbank/phdusa.dram_bank
    echo $$ > /sys/fs/cgroup/corun_diffbank/tasks
    echo 2 > /sys/kernel/debug/color_page_alloc/debug_level
    ./profile-corun.sh &
    
    echo 2,3 > /sys/fs/cgroup/spec2006/phdusa.dram_rank
    echo 0-3 > /sys/fs/cgroup/spec2006/phdusa.dram_bank
    echo $$ > /sys/fs/cgroup/spec2006/tasks
    ./profile.sh 0
done


log_echo '8B-diffbank-LO-w/spec'
for i in `seq 1 $repeat`; do
    echo 0-3 > /sys/fs/cgroup/corun_diffbank/phdusa.dram_rank
    echo 0,1 > /sys/fs/cgroup/corun_diffbank/phdusa.dram_bank
    echo $$ > /sys/fs/cgroup/corun_diffbank/tasks
    echo 2 > /sys/kernel/debug/color_page_alloc/debug_level
    ./profile-corun.sh &
    
    echo 0-3 > /sys/fs/cgroup/spec2006/phdusa.dram_rank
    echo 2,3 > /sys/fs/cgroup/spec2006/phdusa.dram_bank
    echo $$ > /sys/fs/cgroup/spec2006/tasks
    ./profile.sh 0
done

exit


log_echo '8B-samebank-HI-w/spec'
for i in `seq 1 $repeat`; do
    echo 0,1 > /sys/fs/cgroup/corun_samebank/phdusa.dram_rank
    echo 0-3 > /sys/fs/cgroup/corun_samebank/phdusa.dram_bank
    echo $$ > /sys/fs/cgroup/corun_samebank/tasks
    echo 2 > /sys/kernel/debug/color_page_alloc/debug_level
    ./profile-corun.sh &
    
    echo 0,1 > /sys/fs/cgroup/spec2006/phdusa.dram_rank
    echo 0-3 > /sys/fs/cgroup/spec2006/phdusa.dram_bank
    echo $$ > /sys/fs/cgroup/spec2006/tasks
    ./profile.sh 0
done


log_echo '8B-samebank-LO-w/spec'
for i in `seq 1 $repeat`; do
    echo 0-3 > /sys/fs/cgroup/corun_diffbank/phdusa.dram_rank
    echo 0,1 > /sys/fs/cgroup/corun_diffbank/phdusa.dram_bank
    echo $$ > /sys/fs/cgroup/corun_diffbank/tasks
    echo 2 > /sys/kernel/debug/color_page_alloc/debug_level
    ./profile-corun.sh &
    
    echo 0-3 > /sys/fs/cgroup/spec2006/phdusa.dram_rank
    echo 0,1 > /sys/fs/cgroup/spec2006/phdusa.dram_bank
    echo $$ > /sys/fs/cgroup/spec2006/tasks
    ./profile.sh 0
done



echo 99 > /sys/kernel/debug/color_page_alloc/debug_level
log_echo 'corun-buddy'
for i in `seq 1 $repeat`; do
    ./profile-corun.sh &
    ./profile.sh 0
done

exit
