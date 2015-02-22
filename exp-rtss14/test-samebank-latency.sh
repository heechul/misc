#!/bin/bash

. ./functions # MAXCPU, SYSTEM

PATH=$PATH:..

cleanup()
{
    killall latency latency-mlp bandwidth
    kill_spec >& /dev/null
    sleep 1
    echo flush > /sys/kernel/debug/palloc/control
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

cleanup >& /dev/null

outputfile=log.txt

if [ ! -d "/sys/fs/cgroup/corun_samebank" ]; then
    echo "run init-spec2006-cgroup.sh"
    exit
fi

set_pbpc
# set_buddy
# set_worst

# log_echo "diffbank [0,4,8,12] experiments"

size_in_kb=16384
# size_in_kb=12000

# cleanup
# log_echo "case1: latency vs. latency x3 on a same bank."
# output=`latency -m $size_in_kb -c  0 -i 100 2> /dev/null | grep bandwidth`
# log_echo $output
# for cpu in `seq 1 $MAXCPU`; do 
#     latency -m $size_in_kb -c  $cpu -i 1000000000 >& /dev/null &
#     output=`latency -m $size_in_kb -c  0 -i 100 2> /dev/null | grep bandwidth`
#     log_echo $output
# done
# cleanup	

# log_echo "case2: latency(seq) vs. latency(seq)"
# output=`latency -m $size_in_kb -c 0 -s -i 100 2> /dev/null | grep bandwidth`
# log_echo $output
# for cpu in `seq 1 $MAXCPU`; do 
#     latency -m $size_in_kb -c  $cpu -s -i 1000000000 >& /dev/null &
#     output=`latency -m $size_in_kb -c 0 -s -i 100 2> /dev/null | grep bandwidth`
#     log_echo $output
# done	
# cleanup	

print_latency()
{
    input=$1
    x=`echo $input | awk '{ print $5 " " $8 " " $12 }'`
    log_echo $x
}



cleanup >& /dev/null

# mlp=1
# log_echo "case3: latency vs. latency-mlp -l $mlp"
# log_echo "case3: latency -s vs. bandwidth -a write"
log_echo "case3: latency vs. bandwidth -a read"
# log_echo "case3: latency vs. spec"

echo $$ > /sys/fs/cgroup/spec2006/tasks

output=`latency -m $size_in_kb -c 0 -i 100 2> /dev/null`
print_latency "$output"

for cpu in `seq 1 $MAXCPU`; do 
    echo $$ > /sys/fs/cgroup/core$cpu/tasks
    # latency-mlp -m $size_in_kb -c  $cpu -l $mlp -i 1000000000 >& /dev/null &
    bandwidth -m $size_in_kb -c $cpu -t 1000000 -a read >& /dev/null &
    # run_bench 462.libquantum $cpu &
    sleep 3
    echo $$ > /sys/fs/cgroup/spec2006/tasks
    output=`latency -m $size_in_kb -c 0 -i 100 2> /dev/null`
    print_latency "$output"
    # cleanup >& /dev/null
done	
cleanup >& /dev/null


# cleanup
# for mlp in `seq 1 10`; do
#     log_echo "case3: latency-mlp -l $mlp vs. latency-mlp -l $mlp"
#     for cpu in `seq 1 $MAXCPU`; do 
# 	echo $$ > /sys/fs/cgroup/core$cpu/tasks
# 	latency-mlp -m $size_in_kb -c  $cpu -l $mlp -i 1000000000 >& /dev/null &
#     done	
#     echo $$ > /sys/fs/cgroup/spec2006/tasks
#     output=`latency-mlp -m $size_in_kb -c 0 -l $mlp -i 100 2> /dev/null | grep bandwidth`
#     log_echo $output
#     cleanup	>& /dev/null
# done
