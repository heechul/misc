#!/bin/bash 

. functions_memguard

PATH=$PATH:..

outputfile=bw_profile_2.txt

set_cgroup_bins()
{
    cg="$1"
    bins="$2"
    log_echo "4B-[$bins]"
    echo 1073741824 > /sys/fs/cgroup/$cg/memory.limit_in_bytes || error "No cgroup $cg"
    echo $bins  > /sys/fs/cgroup/$cg/palloc.bins || error "Bins $bins error"
    echo $$ > /sys/fs/cgroup/$cg/tasks

    echo 1 > /sys/kernel/debug/palloc/use_palloc
    echo 2 > /sys/kernel/debug/palloc/debug_level
    echo 4 > /sys/kernel/debug/palloc/alloc_balance
}

do_bw_sensitivity_test()
{
    for bw in 300 400 500 600 700 800 900 1000; do # 1000 2000 3000 4000
	mbs="$bw $bw $bw $bw"
	do_init_mb "$mbs" 0 5
	log_echo "MG: BWs=$mbs"
	# ./profile.sh solo $outputfile
	./profile.sh corun $outputfile
	rmmod memguard
	sync
    done

   log_echo "MG: NoMG"
   # ./profile.sh solo $outputfile
   ./profile.sh corun $outputfile
   sync
}

log_echo 'Buddy'
echo 0 > /sys/kernel/debug/palloc/use_palloc
do_bw_sensitivity_test

echo 1 > /sys/kernel/debug/palloc/use_palloc
echo 2 > /sys/kernel/debug/palloc/debug_level
echo 4 > /sys/kernel/debug/palloc/alloc_balance

log_echo 'PB'
set_cgroup_bins spec2006 "0-3"
set_cgroup_bins core1 "4-7"
set_cgroup_bins core2 "8-11"
set_cgroup_bins core3 "12-15"
do_bw_sensitivity_test

log_echo 'PB+PC'
set_cgroup_bins spec2006 "0,4,8,12"
set_cgroup_bins core1 "1,5,9,13"
set_cgroup_bins core2 "2,6,10,14"
set_cgroup_bins core3 "3,7,11,15"
do_bw_sensitivity_test

chown heechul.heechul $outputfile
