#!/bin/bash

PATH=$PATH:..
MAXCPU=3
DBGFS=/sys/kernel/debug/palloc

error()
{
    echo "ERR: $*"
    exit
}

log_echo()
{
   echo "$*"
   echo $* >> $outputfile
}

cleanup()
{
    killall latency latency-mlp bandwidth
    kill_spec >& /dev/null
    sleep 1
    echo flush > /sys/kernel/debug/palloc/control
}


set_palloc_config()
{
    SYSTEM=`hostname`
    echo "initialize palloc configuration."

    if [ "$SYSTEM" = "odroid" ]; then
	MASK=0x00006000   # bank bits: 13,14
    elif [ "$SYSTEM" = "icecream" ]; then
	MASK=0x0000c000   # bank bits: 12,13
    else
	error "no palloc config is available"
    fi
    echo $MASK > $DBGFS/palloc_mask
    cat $DBGFS/control
    cat $DBGFS/use_mc_xor
}

set_spec2006_cgroup()
{
    mkdir /sys/fs/cgroup/spec2006
    pushd /sys/fs/cgroup/spec2006

    echo 0      > cpuset.cpus
    echo 0      > cpuset.mems
    echo 950000 > cpu.rt_runtime_us # to allow RT schedulers
    popd
}
set_percore_cgroup()
{
    for cpu in `seq 1 $MAXCPU`; do
	[ ! -d "/sys/fs/cgroup/core$cpu" ] && mkdir -v /sys/fs/cgroup/core$cpu
	pushd /sys/fs/cgroup/core$cpu
	echo 0-$MAXCPU   	> cpuset.cpus
	echo 0    	> cpuset.mems
	popd
    done
}

set_buddy()
{
    PALLOC_MODE="buddy"
    log_echo $PALLOC_MODE
    echo 0 > /sys/kernel/debug/palloc/use_palloc
    echo "flush" > /sys/kernel/debug/palloc/control
}

set_pbpc()
{
    set_buddy

    PALLOC_MODE="PB+PC"
    log_echo $PALLOC_MODE
    set_cgroup_bins spec2006 "0"
    set_cgroup_bins core1 "1"
    set_cgroup_bins core2 "2"
    set_cgroup_bins core3 "3"
    echo 1 > /sys/kernel/debug/palloc/use_palloc
    echo 2 > /sys/kernel/debug/palloc/debug_level
    echo 4 > /sys/kernel/debug/palloc/alloc_balance
}

# same cache partition (2MB), same bank partition
set_worst()
{
    set_buddy

    PALLOC_MODE="PB+PC"
    log_echo $PALLOC_MODE
    set_cgroup_bins spec2006 "0"
    set_cgroup_bins core1 "0"
    set_cgroup_bins core2 "0"
    set_cgroup_bins core3 "0"
    echo 1 > /sys/kernel/debug/palloc/use_palloc
    echo 2 > /sys/kernel/debug/palloc/debug_level
    echo 4 > /sys/kernel/debug/palloc/alloc_balance
}

set_cgroup_bins()
{
    cg="$1"
    bins="$2"
    log_echo "Bins[$bins]"
    echo 200000000 > /sys/fs/cgroup/$cg/memory.limit_in_bytes || error "No cgroup $cg"
    echo $bins  > /sys/fs/cgroup/$cg/palloc.bins || error "Bins $bins error"
    echo $$ > /sys/fs/cgroup/$cg/tasks

    echo 0-$MAXCPU > /sys/fs/cgroup/$cg/cpuset.cpus
    echo 0 > /sys/fs/cgroup/$cg/cpuset.mems
}

test_latency_vs_latency()
{
    size_in_kb_corun=$1
    [ -z "$size_in_kb_corun" ] && error "size_in_kb_corun is not set"
    print_env
    cleanup >& /dev/null
    log_echo "latency($size_in_kb_subject) latency($size_in_kb_corun)"
    
    [ "$use_part" = "yes" ] && echo $$ > /sys/fs/cgroup/spec2006/tasks
    output=`latency -m $size_in_kb_subject -c 0 -i 10000 2> /dev/null | grep average | awk '{ print $2 }'`
    log_echo $output
    for cpu in `seq 1 $MAXCPU`; do 
	[ "$use_part" = "yes" ] && echo $$ > /sys/fs/cgroup/core$cpu/tasks
	latency -m $size_in_kb_corun -c  $cpu -i 1000000000 >& /dev/null &
	sleep 3
	[ "$use_part" = "yes" ] && echo $$ > /sys/fs/cgroup/spec2006/tasks
	output=`latency -m $size_in_kb_subject -c 0 -i 10000 2> /dev/null | grep average | awk '{ print $2 }'`
	log_echo $output
    # cleanup >& /dev/null
    done	
    cleanup >& /dev/null
}

print_allocated_colors()
{
    pgm=$1
    for pid in `pidof $pgm`; do
	pagetype -p $pid | grep "color"
    done
}

test_latency_vs_bandwidth()
{
    size_in_kb_corun=$1
    acc_type=$2
    [ -z "$acc_type" -o -z "$size_in_kb_corun" ] && error "size_in_kb_corun or acc_type is not set"
    print_env
    cleanup >& /dev/null
    log_echo "latency($size_in_kb_subject) bandwidth_$acc_type ($size_in_kb_corun)"

    if [ "$use_part" = "yes" ]; then 
	set_pbpc
	echo $$ > /sys/fs/cgroup/spec2006/tasks
    else
	set_buddy
	bandwidth -m 1000000 -t 1
	# set_pbpc
	# echo $$ > /sys/fs/cgroup/tasks
	# echo 0,1,2,3 > /sys/fs/cgroup/palloc.bins
    fi

    output=`latency -m $size_in_kb_subject -c 0 -i 10000 2> /dev/null | grep average | awk '{ print $2 }'`
    log_echo $output
    for cpu in `seq 1 $MAXCPU`; do 
	[ "$use_part" = "yes" ] && echo $$ > /sys/fs/cgroup/core$cpu/tasks
    # latency-mlp -m $size_in_kb -c  $cpu -l $mlp -i 1000000000 >& /dev/null &
	bandwidth -m $size_in_kb_corun -c $cpu -t 1000000 -a $acc_type >& /dev/null &
    # run_bench 462.libquantum $cpu &
	print_allocated_colors bandwidth
	sleep 3
	[ "$use_part" = "yes" ] && echo $$ > /sys/fs/cgroup/spec2006/tasks
	output=`latency -m $size_in_kb_subject -c 0 -i 10000 2> /dev/null | grep average | awk '{ print $2 }'`
	log_echo $output
    # cleanup >& /dev/null
    done	
    cleanup >& /dev/null
}

test_bandwidth_vs_bandwidth()
{
    size_in_kb_corun=$1
    acc_type=$2
    [ -z "$acc_type" -o -z "$size_in_kb_corun" ] && error "size_in_kb_corun or acc_type is not set"
    print_env
    cleanup >& /dev/null
    log_echo "bandwidth_read ($size_in_kb_subject) bandwidth_$acc_type ($size_in_kb_corun)"
    
    if [ "$use_part" = "yes" ]; then 
	set_pbpc
	echo $$ > /sys/fs/cgroup/spec2006/tasks
    else
	set_buddy
	bandwidth -m 1000000 -t 1
    fi

    output=`bandwidth -m $size_in_kb_subject -t 4 -c 0 2> /dev/null | grep average | awk '{ print $10 }'`
    log_echo $output
# perf stat -e cache-misses -o perf.c0.txt bandwidth -m $size_in_kb_subject -t 4 -c 0 2> /dev/null | grep average | awk '{ print $10 }'
    for cpu in `seq 1 $MAXCPU`; do
	[ "$use_part" = "yes" ] && echo $$ > /sys/fs/cgroup/core$cpu/tasks
    # latency-mlp -m $size_in_kb -c  $cpu -l $mlp -i 1000000000 >& /dev/null &
	bandwidth -m $size_in_kb_corun -c $cpu -t 1000000 -a $acc_type >& /dev/null &
    # run_bench 462.libquantum $cpu &
	print_allocated_colors bandwidth
	sleep 3
	[ "$use_part" = "yes" ] && echo $$ > /sys/fs/cgroup/spec2006/tasks
	output=`bandwidth -m $size_in_kb_subject -t 4 -c 0 2> /dev/null | grep average | awk '{ print $10 }'`
	log_echo $output
    # perf stat -e cache-misses -o perf.c$cpu.txt bandwidth -m $size_in_kb_subject -t 4 -c 0 2> /dev/null | grep average | awk '{ print $10 }'
    # cleanup >& /dev/null
    done
    cleanup >& /dev/null
# grep cache-misses perf.c?.txt
}

print_env()
{

    echo size_in_kb_subject=$size_in_kb_subject
    echo size_in_kb_corun=$size_in_kb_corun
    echo use_part=$use_part
    echo acc_type=$acc_type
}

cleanup >& /dev/null

outputfile=log.txt

if [ ! -d "/sys/fs/cgroup/spec2006" ]; then
    set_palloc_config
    set_spec2006_cgroup
    set_percore_cgroup
fi
# set_pbpc
# set_buddy
# set_worst

use_part=no
if grep "0xc0f" /proc/cpuinfo; then
    # cortex-a15
    llc_ws=48
    dram_ws=4096
elif grep "0xc07" /proc/cpuinfo; then
    # cortex-a7
    llc_ws=48
    dram_ws=4096
elif grep "W3530" /proc/cpuinfo; then
    # nehalem
    llc_ws=512
    dram_ws=16384
fi

size_in_kb_subject=$llc_ws

for part in "no" "yes" "no"; do
    use_part=$part
#    test_latency_vs_latency $dram_ws
    test_latency_vs_bandwidth $dram_ws "read"
    # test_bandwidth_vs_bandwidth $dram_ws "read"
    # test_bandwidth_vs_bandwidth $llc_ws "read"
    # test_latency_vs_bandwidth $dram_ws "write"
    # test_bandwidth_vs_bandwidth $dram_ws "write"
    # test_bandwidth_vs_bandwidth $llc_ws "write"
done
