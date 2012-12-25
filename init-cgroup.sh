#!/bin/bash

init_system()
{
    if !(mount | grep cgroup); then
	mount -t cgroup xxx /sys/fs/cgroup
    fi
}

set_system_cgroup()
{
    mkdir /sys/fs/cgroup/system
    pushd /sys/fs/cgroup/system
    echo 0 > cpuset.cpus
    echo 0 > cpuset.mems
    for t in `cat /sys/fs/cgroup/tasks`; do
        echo $t > tasks
    done 2> /dev/null
}


set_core_cgroup()
{
    core=$1
    patt=$2
    mask=$3
    mkdir /sys/fs/cgroup/core${core}
    pushd /sys/fs/cgroup/core${core}
    echo $core > cpuset.cpus
    echo 0 > cpuset.mems
    echo $patt > phdusa.phys_pattern
    echo $mask > phdusa.phys_mask
}

init_system
TARGET=$1
[ -z "$TARGET" ] && TARGET=i5

echo "target=$TARGET"
if [ "$TARGET" = "odroid" ]; then
	NCOLOR=16
	set_core_cgroup 0 0  12
	set_core_cgroup 1 4  12
	set_core_cgroup 2 8  12
	set_core_cgroup 3 12 12
	# 1100 
elif [ "$TARGET" = "core2quad" ]; then
	NCOLOR=64
	set_core_cgroup 0 0 32
	set_core_cgroup 1 32 32
	set_core_cgroup 2 0 32
	set_core_cgroup 3 32 32
	# 1 0000 
elif [ "$TARGET" = "i5" ]; then
	NCOLOR=64
	set_core_cgroup 0  0 48 
	set_core_cgroup 1 16 48 
	set_core_cgroup 2 32 48
	set_core_cgroup 3 48 48
	# 11 0000 
fi

echo "$NCOLOR" > /sys/kernel/debug/color_page_alloc/colors
echo 4 > /sys/kernel/debug/color_page_alloc/debug_level
echo 2 > /sys/kernel/debug/color_page_alloc/enable

echo "target=$TARGET"
echo "ncolor=$NCOLOR"
