#!/bin/bash
. ./functions

outputfile=hrt-palloc.txt

set_cgroup()
{
    cgname="$1"
    cpus="$2"
    bank="$3"
    rank="$4"
    rtus="$5"
    mount | grep cgroup || mount -t cgroup xxx /sys/fs/cgroup
    [ ! -d "/sys/fs/cgroup/$cgname" ] && mkdir /sys/fs/cgroup/$cgname
    echo "$cpus" > /sys/fs/cgroup/$cgname/cpuset.cpus
    echo 0       > /sys/fs/cgroup/$cgname/cpuset.mems
    echo 1024    > /sys/fs/cgroup/$cgname/cpu.shares
    echo "cgroup=$cgname rtus=$rtus"
    echo "$rtus" > /sys/fs/cgroup/$cgname/cpu.rt_runtime_us
    echo "$bank" > /sys/fs/cgroup/$cgname/phdusa.dram_bank
    echo "$rank" > /sys/fs/cgroup/$cgname/phdusa.dram_rank
    echo 0       > /sys/fs/cgroup/$cgname/phdusa.colors
    echo $$      > /sys/fs/cgroup/$cgname/tasks
}

do_hrt_test()
{
    local subject=$1
    local corun=$2
    local bankset=$3
    local FILENAME=$4
    local TMPFILE=/run/$FILENAME

    killall -2 thr hrt bandwidth latency
    killall -9 cpuhog
    echo $$ > /sys/fs/cgroup/tasks

    # corun
    [ "$bankset" = "samebank" ] && set_cgroup "corun" "1-3" "0" "0" 0 
    [ "$bankset" = "diffbank" ] && set_cgroup "corun" "1-3" "1-7" "0,1" 0 
    if [ "$corun" = "bandwidth" ]; then
	log_echo "co-run w/ 'bandwidth'"
	./bandwidth -a write -c 1 -t 1000000 -f bwlog.c1 &
#	./bandwidth -a write -c 2 -t 1000000 -f bwlog.c2 &
#	./bandwidth -a write -c 3 -t 1000000 -f bwlog.c3 &
    fi

    echo $$ > /sys/fs/cgroup/tasks

    # subject
    [ "$bankset" = "samebank" ] && set_cgroup "hrt"   "0" "0" "0"   950000  # hrt
    [ "$bankset" = "diffbank" ] && set_cgroup "hrt"   "0" "0" "0"   950000  # hrt
    ./hrt -c 0 -i 1000 -C 12 -I 20 > $TMPFILE \
	|| error "exec failed"

    killall -2 thr hrt bandwidth latency cpuhog matrix
    sleep 1

    cp -v $TMPFILE $FILENAME.dat
    awk '{ print $2 }' $TMPFILE > $TMPFILE.dat
    ./printstat.py --deadline=13 $TMPFILE.dat >> $outputfile
    cp $TMPFILE rawdata.dat
    gnuplot histo.scr > $FILENAME.eps
    log_echo "------------"
}

test_isolation()
{
    hw=$1
    do_hrt_test hrt bandwidth buddy    $hw-out-buddy-corun
    do_hrt_test hrt bandwidth diffbank $hw-out-diffbank-corun
    do_hrt_test hrt bandwidth samebank $hw-out-samebank-corun
    do_hrt_test hrt none      solo     $hw-out-buddy-solo 
}

test_isolation "p4080" 

