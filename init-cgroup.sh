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
    colors=$2
    for t in `cat /sys/fs/cgroup/core${core}/tasks`; do
	echo $t > /sys/fs/cgroup/tasks
    done
    rmdir /sys/fs/cgroup/core${core}
    mkdir /sys/fs/cgroup/core${core}
    pushd /sys/fs/cgroup/core${core}
    echo $core > cpuset.cpus
    echo 0 > cpuset.mems
    echo $colors > phdusa.colors
}

init_system

set_core_cgroup 0 "0-1"
set_core_cgroup 1 "2-3"
set_core_cgroup 2 "4-5"
set_core_cgroup 3 "6-7"

echo -n "colors: "
cat /sys/kernel/debug/color_page_alloc/colors
echo 4 > /sys/kernel/debug/color_page_alloc/debug_level

