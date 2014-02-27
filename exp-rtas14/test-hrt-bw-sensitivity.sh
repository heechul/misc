#!/bin/bash 
. functions
. functions_memguard

PATH=$PATH:..


outputfile=tmpoutput.txt
rm $outputfile

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

do_hrt_test()
{
    local FILENAME=hrt-bw-$1
    local TMPFILE=/run/$FILENAME

    killall -2 thr hrt bandwidth latency
    killall -9 cpuhog
    echo $$ > /sys/fs/cgroup/tasks
    if [ "$1" != "solo" ]; then
	echo $$ > /sys/fs/cgroup/core1/tasks; run_bench 470.lbm 1 &
	echo $$ > /sys/fs/cgroup/core2/tasks; run_bench 470.lbm 2 &
	echo $$ > /sys/fs/cgroup/core3/tasks; run_bench 470.lbm 3 &
	sleep 3
    fi
    echo $$ > /sys/fs/cgroup/spec2006/tasks

    hrt -c 0 -o fifo -m 8 -i 1000 -I 100 > $TMPFILE \
	|| error "exec failed"

    killall -2 thr hrt bandwidth latency cpuhog matrix
    kill_spec
    sleep 1

    cp -v $TMPFILE $FILENAME.dat
    awk '{ print $2 }' $TMPFILE > $TMPFILE.dat
    printstat.py --deadline=13 $TMPFILE.dat | grep LINE >> $outputfile
    cp $TMPFILE rawdata.dat
    gnuplot histo.scr > $FILENAME.eps
    log_echo "------------"
}

do_bw_sensitivity_test()
{
    # solo
    log_echo "Solo"
    do_hrt_test solo

    # corun w/ MemGuard
    for bw in 100 200 300 400 500 600 700 800 900 1000; do # 1000 2000 3000 4000
	mbs="10000 $bw $bw $bw"
	do_init_mb "$mbs" 0 0
	log_echo "MG: BWs=$mbs"
	do_hrt_test $bw
	rmmod memguard
	sync
    done

    # corun w/o MemGuard
    log_echo "MG: NoMG"
    do_hrt_test NoMG
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

cat $outputfile >> hrt_bw_profile.txt

grep LINE $outputfile | awk '{ print $2 " " $5 }'

