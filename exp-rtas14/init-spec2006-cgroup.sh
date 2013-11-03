#!/bin/bash
DBGFS=/sys/kernel/debug/phalloc

# system info
SYSTEM=icecream
CH=1
NDIMM=1

error()
{
    echo "ERR: $*"
    exit
}

if [ "$SYSTEM" = "icecream" ]; then
    MAXCPU=3 # CPU 0-3
    if [ $CH -eq 1 ]; then
	if [ $NDIMM -eq 1 ]; then
	    echo "1ch-1DIMM"
	    MASK=0x00183000   # bits: 12, 13, 19, 20
	elif [ $NDIMM -eq 2 ]; then
	    echo "1ch-2DIMM"
	    MASK=0x00107000   # bits: 12, 13, 14, 20, 32(?)
	fi
    elif [ $CH -eq 2 ]; then
	if [ $NDIMM -eq 2 ]; then
	    MASK=0x00116040   # bits:  6, 13, 14, 16, 20
	else
	    error "Not possible CH($CH) and NDIMM($NDIMM)"
	fi
    fi
elif [ "$SYSTEM" = "T61" ]; then
    MAXCPU=1 # CPU 0-1
    MASK=0x0018C000
fi

init_system()
{
    if !(mount | grep cgroup); then
	mount -t cgroup xxx /sys/fs/cgroup
    fi
    echo $MASK > $DBGFS/phalloc_mask
    echo flush > $DBGFS/control
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

set_corun_samebank_cgroup()
{
    mkdir /sys/fs/cgroup/corun_samebank
    pushd /sys/fs/cgroup/corun_samebank

    echo 0-$MAXCPU   	> cpuset.cpus
    echo 0    	> cpuset.mems
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

set_corun_diffbank_cgroup()
{
    mkdir /sys/fs/cgroup/corun_diffbank
    pushd /sys/fs/cgroup/corun_diffbank

    echo 0-$MAXCPU   	> cpuset.cpus
    echo 0    	> cpuset.mems
    popd
}


init_system

set_spec2006_cgroup
set_corun_samebank_cgroup
set_corun_diffbank_cgroup
set_percore_cgroup

echo "128" > /sys/kernel/debug/tracing/buffer_size_kb
echo 1 > $DBGFS/debug_level
cat $DBGFS/phalloc_mask
