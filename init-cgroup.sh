#!/bin/bash
DBGFS=/sys/kernel/debug/color_page_alloc

CH=1

if [ $CH -eq 1 ]; then
    echo "Single channel configuration"
    BANK_SHIFT=19
    BANK_BITS=2
    RANK_SHIFT=12
    RANK_BITS=2
fi


init_system()
{
    if !(mount | grep cgroup); then
	mount -t cgroup xxx /sys/fs/cgroup
    fi
    echo $BANK_SHIFT > $DBGFS/dram_bank_shift
    echo $BANK_BITS > $DBGFS/dram_bank_bits

    echo $RANK_SHIFT > $DBGFS/dram_rank_shift
    echo $RANK_BITS > $DBGFS/dram_rank_bits

    echo flush > $DBGFS/control
    echo 0 > $DBGFS/cache_color_bits
}


set_system_cgroup()
{
    mkdir /sys/fs/cgroup/system
    pushd /sys/fs/cgroup/system
    echo 0      > cpuset.cpus
    echo 0      > cpuset.mems
    for t in `cat /sys/fs/cgroup/tasks`; do
        echo $t > tasks
    done 2> /dev/null
    popd
}

set_corun_samebank_cgroup()
{
    mkdir /sys/fs/cgroup/corun_samebank
    pushd /sys/fs/cgroup/corun_samebank

    echo 0-3    > cpuset.cpus
    echo 0      > cpuset.mems
    echo 0      > phdusa.dram_rank
    echo 0      > phdusa.dram_bank
    echo 0      > phdusa.colors
    popd
}

set_corun_diffbank_cgroup()
{
    mkdir /sys/fs/cgroup/corun_diffbank
    pushd /sys/fs/cgroup/corun_diffbank

    echo 0-3   > cpuset.cpus
    echo 0      > cpuset.mems
    echo 0      > phdusa.dram_rank
    echo 1      > phdusa.dram_bank
    echo 0      > phdusa.colors
    popd
}

set_corun_samebankdiffrank_cgroup()
{
    mkdir /sys/fs/cgroup/corun_samebankdiffrank
    pushd /sys/fs/cgroup/corun_samebankdiffrank

    echo 0-3    > cpuset.cpus
    echo 0      > cpuset.mems
    echo 1      > phdusa.dram_rank
    echo 0      > phdusa.dram_bank
    echo 0      > phdusa.colors
    popd
}

init_dram_config()
{
    core=$1
    banks=$2
    for t in `cat /sys/fs/cgroup/core${core}/tasks`; do
        echo $t > /sys/fs/cgroup/tasks
    done
    direc="/sys/fs/cgroup/core${core}"
    [ -d "$direc" ] && rmdir $direc
    mkdir /sys/fs/cgroup/core${core}
    pushd /sys/fs/cgroup/core${core}
    echo $core > cpuset.cpus
    echo 0 > cpuset.mems

    #echo 0-7    > phdusa.colors
    echo 1      > phdusa.dram_rank
    echo $banks > phdusa.dram_bank
    echo 0      > phdusa.colors
    popd
}

run_test()
{
    echo flush > /sys/kernel/debug/color_page_alloc/control
    echo reset > /sys/kernel/debug/color_page_alloc/control

    for i in `seq 1 3`; do ./latency -c 0 -m 3072 2> /dev/null | grep MB; done
#    for i in `seq 1 3`; do ./bandwidth -t 1 | grep MB; done
    cat /sys/kernel/debug/color_page_alloc/control
}

set_core_cgroup 0 "0"  # <test core

set_core_cgroup 1 "1"
set_core_cgroup 2 "2"
set_core_cgroup 3 "3"

set_corun_samebank_cgroup
set_corun_diffbank_cgroup
set_corun_samebankdiffrank_cgroup

echo "128" > /sys/kernel/debug/tracing/buffer_size_kb

echo 2 > $DBGFS/debug_level
for f in $DBGFS/dram_*; do 
    echo $f `cat $f`
done
