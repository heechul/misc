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


set_spec2006_cgroup()
{
    mkdir /sys/fs/cgroup/spec2006
    pushd /sys/fs/cgroup/spec2006

    echo 0      > cpuset.cpus
    echo 0      > cpuset.mems
    echo 0      > phdusa.dram_rank
    echo 0   > phdusa.dram_bank  # total 256MB x 8 = 2GB
    echo 0      > phdusa.colors

    echo 950000 > cpu.rt_runtime_us # to allow RT schedulers

    popd
}

set_corun_diffbank_cgroup()
{
    mkdir /sys/fs/cgroup/corun_diffbank
    pushd /sys/fs/cgroup/corun_diffbank

    echo 0    > cpuset.cpus
    echo 0      > cpuset.mems
    echo 0      > phdusa.dram_rank
    echo 0   > phdusa.dram_bank  # total 256MB x 8 = 2GB
    echo 0      > phdusa.colors
    popd
}


init_system

set_spec2006_cgroup
set_corun_diffbank_cgroup

echo "128" > /sys/kernel/debug/tracing/buffer_size_kb

echo 1 > $DBGFS/debug_level
for f in $DBGFS/dram_*; do 
    echo $f `cat $f`
done
