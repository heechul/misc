#!/bin/bash 

. functions_memguard

PATH=$PATH:..

outputfile=bw_profile.txt

set_cgroup_bins()
{
    bins=$1
    log_echo "4B-[$bins]"
    echo $bins  > /sys/fs/cgroup/spec2006/palloc.bins
    echo $$ > /sys/fs/cgroup/spec2006/tasks
    echo 2 > /sys/kernel/debug/palloc/debug_level
    echo 4 > /sys/kernel/debug/palloc/alloc_balance
}

do_bw_sensitivity_test()
{
    for bw in 1000 2000 4000; do
	do_init_mb "$bw" 0 0
	log_echo "MG: BW=$bw"
	./profile.sh solo $outputfile
    done
    
    log_echo "NoMG"
    rmmod memguard
   ./profile.sh solo $outputfile
}

log_echo 'Buddy'
echo 99 > /sys/kernel/debug/palloc/debug_level
do_bw_sensitivity_test

log_echo 'PB'
set_cgroup_bins "0-3"
do_bw_sensitivity_test

log_echo 'PB+PC'
set_cgroup_bins "0,4,8,12"
do_bw_sensitivity_test

chown heechul.heechul $outputfile