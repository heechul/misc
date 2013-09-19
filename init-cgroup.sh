#!/bin/bash
init_system()
{
#    serivce lightdm stop
    if !(mount | grep cgroup); then
	mount -t cgroup xxx /sys/fs/cgroup
    fi
    echo 4096 >  /sys/kernel/debug/tracing/buffer_size_kb
}


set_test_cgroup()
{
    local name=test
    local bank=$1
    local rank=$2
    local color=$3
    [ -d "/sys/fs/cgroup/$name" ] || mkdir /sys/fs/cgroup/$name
    pushd /sys/fs/cgroup/$name
    echo 0 > cpuset.cpus
    echo 0 > cpuset.mems
    echo $bank > phdusa.dram_bank
    echo $rank > phdusa.dram_rank
    echo $color > phdusa.colors
    popd
}

set_corun_cgroup()
{
    local name=corun
    local bank=$1
    local rank=$2
    local color=$3
    [ -d "/sys/fs/cgroup/$name" ] || mkdir /sys/fs/cgroup/$name
    pushd /sys/fs/cgroup/$name
    echo 0-3 > cpuset.cpus
    echo 0 > cpuset.mems
    echo $bank > phdusa.dram_bank
    echo $rank > phdusa.dram_rank
    echo $color > phdusa.colors
    popd
}

init_dram_config()
{
    echo 2 > /sys/kernel/debug/color_page_alloc/debug_level
    echo flush > /sys/kernel/debug/color_page_alloc/control

    pushd /sys/kernel/debug/color_page_alloc
    echo 13 > dram_bank_shift
    echo  3 > dram_bank_bits
    echo 16 > dram_rank_shift
    echo  1 > dram_rank_bits
    echo 12 > cache_color_shift
    echo  1 > cache_color_bits

    for f in dram* cache_*; do
	echo -n "$f: "
	cat $f
    done

    popd

    echo flush > /sys/kernel/debug/color_page_alloc/control
}

run_test()
{
    echo flush > /sys/kernel/debug/color_page_alloc/control
    echo reset > /sys/kernel/debug/color_page_alloc/control

    for i in `seq 1 3`; do ./latency -c 0 -m 3072 2> /dev/null | grep MB; done
#    for i in `seq 1 3`; do ./bandwidth -t 1 | grep MB; done
    cat /sys/kernel/debug/color_page_alloc/control
}

wait()
{
	buffer=""
	echo "press key to continue"
	read buffer
}


init_system
init_dram_config

set_test_cgroup 0 0 0
set_corun_cgroup 0-7 0,1 1
echo "0 0 0,1"
wait
run_test
