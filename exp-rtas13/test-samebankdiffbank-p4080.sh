#!/bin/bash

. functions

outputfile=log.txt

set_cpus "1 1 1 1"
init_cgroup


if [ ! -d "/sys/fs/cgroup/corun_samebank" ]; then
    mkdir /sys/fs/cgroup/corun_samebank
fi
echo 0-7 > /sys/fs/cgroup/corun_samebank/cpuset.cpus
echo 0 > /sys/fs/cgroup/corun_samebank/cpuset.mems
echo 0 > /sys/fs/cgroup/corun_samebank/phdusa.dram_bank
echo 0 > /sys/fs/cgroup/corun_samebank/phdusa.dram_rank
echo 0 > /sys/fs/cgroup/corun_samebank/phdusa.colors
echo $$ > /sys/fs/cgroup/corun_samebank/tasks

killall latency	
echo "samebank"
./latency -c 0 -i 100 2> /dev/null | grep bandwidth

./latency -c 1 -i 1000000000 >& /dev/null &
./latency -c 0 -i 100 2> /dev/null | grep bandwidth
	
./latency -c 2 -i 1000000000 >& /dev/null &
./latency -c 0 -i 100 2> /dev/null | grep bandwidth
	
./latency -c 3 -i 1000000000 >& /dev/null &
./latency -c 0 -i 100 2> /dev/null | grep bandwidth

./latency -c 4 -i 1000000000 >& /dev/null &
./latency -c 0 -i 100 2> /dev/null | grep bandwidth

./latency -c 5 -i 1000000000 >& /dev/null &
./latency -c 0 -i 100 2> /dev/null | grep bandwidth

./latency -c 6 -i 1000000000 >& /dev/null &
./latency -c 0 -i 100 2> /dev/null | grep bandwidth

./latency -c 7 -i 1000000000 >& /dev/null &
./latency -c 0 -i 100 2> /dev/null | grep bandwidth


killall latency	
echo "diffbank B1-15"
echo 0-7 > /sys/fs/cgroup/corun_diffbank/cpuset.cpus
echo 1-7 > /sys/fs/cgroup/corun_diffbank/phdusa.dram_bank
echo 0,1 > /sys/fs/cgroup/corun_diffbank/phdusa.dram_rank
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

echo $$ > /sys/fs/cgroup/corun_diffbank/tasks
./latency -c 4 -i 1000000000 >& /dev/null &
echo $$ > /sys/fs/cgroup/corun_samebank/tasks
./latency -c 0 -i 100 2> /dev/null | grep bandwidth

echo $$ > /sys/fs/cgroup/corun_diffbank/tasks
./latency -c 5 -i 1000000000 >& /dev/null &
echo $$ > /sys/fs/cgroup/corun_samebank/tasks
./latency -c 0 -i 100 2> /dev/null | grep bandwidth

echo $$ > /sys/fs/cgroup/corun_diffbank/tasks
./latency -c 6 -i 1000000000 >& /dev/null &
echo $$ > /sys/fs/cgroup/corun_samebank/tasks
./latency -c 0 -i 100 2> /dev/null | grep bandwidth

echo $$ > /sys/fs/cgroup/corun_diffbank/tasks
./latency -c 7 -i 1000000000 >& /dev/null &
echo $$ > /sys/fs/cgroup/corun_samebank/tasks
./latency -c 0 -i 100 2> /dev/null | grep bandwidth


killall latency	
echo "diffbank B1"
echo 0-7 > /sys/fs/cgroup/corun_diffbank/cpuset.cpus
echo 1 > /sys/fs/cgroup/corun_diffbank/phdusa.dram_bank
echo 0 > /sys/fs/cgroup/corun_diffbank/phdusa.dram_rank
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

echo $$ > /sys/fs/cgroup/corun_diffbank/tasks
./latency -c 4 -i 1000000000 >& /dev/null &
echo $$ > /sys/fs/cgroup/corun_samebank/tasks
./latency -c 0 -i 100 2> /dev/null | grep bandwidth

echo $$ > /sys/fs/cgroup/corun_diffbank/tasks
./latency -c 5 -i 1000000000 >& /dev/null &
echo $$ > /sys/fs/cgroup/corun_samebank/tasks
./latency -c 0 -i 100 2> /dev/null | grep bandwidth

echo $$ > /sys/fs/cgroup/corun_diffbank/tasks
./latency -c 6 -i 1000000000 >& /dev/null &
echo $$ > /sys/fs/cgroup/corun_samebank/tasks
./latency -c 0 -i 100 2> /dev/null | grep bandwidth

echo $$ > /sys/fs/cgroup/corun_diffbank/tasks
./latency -c 7 -i 1000000000 >& /dev/null &
echo $$ > /sys/fs/cgroup/corun_samebank/tasks
./latency -c 0 -i 100 2> /dev/null | grep bandwidth

