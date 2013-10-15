#!/bin/bash

. functions

outputfile=log.txt

set_cpus "1 1 1 1"
init_cgroup


if [ ! -d "/sys/fs/cgroup/corun_samebank" ]; then
    mkdir /sys/fs/cgroup/corun_samebank
fi
echo 0-3 > /sys/fs/cgroup/corun_samebank/cpuset.cpus
echo 0 > /sys/fs/cgroup/corun_samebank/cpuset.mems
echo 0 > /sys/fs/cgroup/corun_samebank/phdusa.dram_bank
echo 0 > /sys/fs/cgroup/corun_samebank/phdusa.dram_rank
echo 0 > /sys/fs/cgroup/corun_samebank/phdusa.colors
echo $$ > /sys/fs/cgroup/corun_samebank/tasks

killall latency	
echo "samebank [$hi-$lo] experiments"
./latency -c 0 -i 100 2> /dev/null | grep bandwidth

./latency -c 1 -i 1000000000 >& /dev/null &
./latency -c 0 -i 100 2> /dev/null | grep bandwidth
	
./latency -c 2 -i 1000000000 >& /dev/null &
./latency -c 0 -i 100 2> /dev/null | grep bandwidth
	
./latency -c 3 -i 1000000000 >& /dev/null &
./latency -c 0 -i 100 2> /dev/null | grep bandwidth



killall latency	
echo "diffbank B1-15"
echo 0-3 > /sys/fs/cgroup/corun_diffbank/cpuset.cpus
echo 0-3 > /sys/fs/cgroup/corun_diffbank/phdusa.dram_bank
echo 1-3 > /sys/fs/cgroup/corun_diffbank/phdusa.dram_rank
echo 0 > /sys/fs/cgroup/corun_diffbank/phdusa.colors

echo $$ > /sys/fs/cgroup/corun_samebank/tasks
./latency -c 0 -i 100 2> /dev/null | grep bandwidth

echo $$ > /sys/fs/cgroup/corun_diffbank/tasks
./latency -c 1 -i 1000000000 >& /dev/null &
echo $$ > /sys/fs/cgroup/corun_samebank/tasks
./latency -c 0 -i 100 2> /dev/null | grep bandwidth

echo $$ > /sys/fs/cgroup/corun_diffbank/tasks
./latency -c 2 -i 1000000000 >& /dev/null &
echo $$ > /sys/fs/cgroup/corun_samebank/tasks
./latency -c 0 -i 100 2> /dev/null | grep bandwidth

echo $$ > /sys/fs/cgroup/corun_diffbank/tasks
./latency -c 3 -i 1000000000 >& /dev/null &
echo $$ > /sys/fs/cgroup/corun_samebank/tasks
./latency -c 0 -i 100 2> /dev/null | grep bandwidth


killall latency	
echo "diffbank B1"
echo 0-3 > /sys/fs/cgroup/corun_diffbank/cpuset.cpus
echo 0 > /sys/fs/cgroup/corun_diffbank/phdusa.dram_bank
echo 1 > /sys/fs/cgroup/corun_diffbank/phdusa.dram_rank
echo 0 > /sys/fs/cgroup/corun_diffbank/phdusa.colors

echo $$ > /sys/fs/cgroup/corun_samebank/tasks
./latency -c 0 -i 100 2> /dev/null | grep bandwidth

echo $$ > /sys/fs/cgroup/corun_diffbank/tasks
./latency -c 1 -i 1000000000 >& /dev/null &
echo $$ > /sys/fs/cgroup/corun_samebank/tasks
./latency -c 0 -i 100 2> /dev/null | grep bandwidth

echo $$ > /sys/fs/cgroup/corun_diffbank/tasks
./latency -c 2 -i 1000000000 >& /dev/null &
echo $$ > /sys/fs/cgroup/corun_samebank/tasks
./latency -c 0 -i 100 2> /dev/null | grep bandwidth

echo $$ > /sys/fs/cgroup/corun_diffbank/tasks
./latency -c 3 -i 1000000000 >& /dev/null &
echo $$ > /sys/fs/cgroup/corun_samebank/tasks
./latency -c 0 -i 100 2> /dev/null | grep bandwidth
killall latency	
exit




killall latency	
echo "buddy experiments"
echo $$ > /sys/fs/cgroup/tasks
./latency -c 0 -i 100 2> /dev/null | grep bandwidth

./latency -c 1 -i 1000000000 >& /dev/null &
./latency -c 0 -i 100 2> /dev/null | grep bandwidth
	
./latency -c 2 -i 1000000000 >& /dev/null &
./latency -c 0 -i 100 2> /dev/null | grep bandwidth
	
./latency -c 3 -i 1000000000 >& /dev/null &
./latency -c 0 -i 100 2> /dev/null | grep bandwidth
exit


