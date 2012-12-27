init_system()
{
    serivce lightdm stop
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
    for t in `cat /sys/fs/cgroup/core${core}/tasks`; do
	echo $t > /sys/fs/cgroup/tasks
    done
    rmdir /sys/fs/cgroup/core${core}
    mkdir /sys/fs/cgroup/core${core}
    pushd /sys/fs/cgroup/core${core}
    echo $core > cpuset.cpus
    echo 0 > cpuset.mems
    echo $patt > phdusa.phys_pattern
    echo $mask > phdusa.phys_mask
}

init_system

TARGET=$1
[ -z "$TARGET" ] && TARGET=odroid

echo "target=$TARGET"
if [ "$TARGET" = "odroid" ]; then
    NCOLOR=16
    set_core_cgroup 0 0  12
    set_core_cgroup 1 4  12
    set_core_cgroup 2 8  12
    set_core_cgroup 3 12 12
elif [ "$TARGET" = "core2quad" ]; then
    NCOLOR=64
    set_core_cgroup 0 0 32
    set_core_cgroup 1 32 32
    set_core_cgroup 2 0 32
    set_core_cgroup 3 32 32
elif [ "$TARGET" = "core2quadB" ]; then
    NCOLOR=32
    set_core_cgroup 0 0 16
    set_core_cgroup 1 16 16
    set_core_cgroup 2 0 16
    set_core_cgroup 3 16 16
elif [ "$TARGET" = "i5" ]; then
    NCOLOR=64
    set_core_cgroup 0 0 1
    set_core_cgroup 1 0 1
    set_core_cgroup 2 1 1
    set_core_cgroup 3 1 1
fi

echo $NCOLOR  > /sys/kernel/debug/color_page_alloc/colors
echo 2 > /sys/kernel/debug/color_page_alloc/debug_level
echo 2 > /sys/kernel/debug/color_page_alloc/enable

