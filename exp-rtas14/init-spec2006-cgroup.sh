#!/bin/bash
DBGFS=/sys/kernel/debug/palloc

# system info
SYSTEM=`hostname`
CH=1
NDIMM=1

error()
{
    echo "ERR: $*"
    exit
}

set_palloc_config()
{
    if [ "$SYSTEM" = "icecream" ]; then
	MAXCPU=3 # CPU 0-3
	if [ $CH -eq 1 ]; then
	    if [ $NDIMM -eq 1 ]; then
		echo "1ch-1DIMM"
		MASK=0x00183000   # bank bits: 12, 13, 19, 20
		echo $MASK > $DBGFS/palloc_mask
	    elif [ $NDIMM -eq 2 ]; then
		echo "1ch-2DIMM"
		MASK=0x00307000   # bank bits: 12, 13, 14, 20, 21
		echo $MASK > $DBGFS/palloc_mask
	    fi
	elif [ $CH -eq 2 ]; then
	    if [ $NDIMM -eq 2 ]; then
		# bank bits: 13, 14, 20, 21
		MASK=0x00116000   
		# channel bits: 6 XOR 16
	    else
		error "Not possible CH($CH) and NDIMM($NDIMM)"
	    fi
	fi
    elif [ "$SYSTEM" = "nemo" ]; then
	MAXCPU=3
	if [ $CH -eq 1 ]; then
	    if [ $NDIMM -eq 1 ]; then
		MASK=0x0001e000 # bank bits: 13 14 15 16
		echo $MASK > $DBGFS/palloc_mask
		echo xor 13 17 > $DBGFS/control
		echo xor 14 18 > $DBGFS/control
		echo xor 15 19 > $DBGFS/control
		echo xor 16 20 > $DBGFS/control
		echo 1 > $DBGFS/use_mc_xor
	    elif [ $NDIMM -eq 2 ]; then
		MASK=0x0003e000 # bank bits: 13 14 15 16 17
		echo $MASK > $DBGFS/palloc_mask
		echo xor 13 18 > $DBGFS/control
		echo xor 14 19 > $DBGFS/control
		echo xor 16 20 > $DBGFS/control
		echo xor 17 21 > $DBGFS/control
		echo 1 > $DBGFS/use_mc_xor
	    fi
	elif [ $CH -eq 2 ]; then
	    if [ $NDIMM -eq 2 ]; then
		# bank bits: (14 XOR 18), (15 XOR 19), (16 XOR 20), (17 XOR 21)
		MASK=0x0003c000   
		echo $MASK > $DBGFS/palloc_mask
		echo xor 14 18 > $DBGFS/control
		echo xor 15 19 > $DBGFS/control
		echo xor 16 20 > $DBGFS/control
		echo xor 17 21 > $DBGFS/control
		echo 1 > $DBGFS/use_mc_xor
		# channel bits: (15 XOR 14 XOR 13 XOR 12 XOR 9 XOR 8 XOR 7)
	    else
		error "Not possible CH($CH) and NDIMM($NDIMM)"
	    fi
	fi
    elif [ "$SYSTEM" = "T61" ]; then
	MAXCPU=1 # CPU 0-1
	MASK=0x0018C000
    fi
}

init_system()
{
    if !(mount | grep cgroup); then
	mount -t cgroup xxx /sys/fs/cgroup
    fi

    set_palloc_config

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
cat $DBGFS/palloc_mask
