#!/bin/bash

. functions # MAXCPU, SYSTEM

killall -9 latency 

outputfile=log.txt

if [ ! -d "/sys/fs/cgroup/corun_samebank" ]; then
    mkdir /sys/fs/cgroup/corun_samebank
fi
echo 0-$MAXCPU > /sys/fs/cgroup/corun_samebank/cpuset.cpus
echo 0 > /sys/fs/cgroup/corun_samebank/cpuset.mems
echo 0 > /sys/fs/cgroup/corun_samebank/phalloc.bins
echo $$ > /sys/fs/cgroup/corun_samebank/tasks

killall latency	
echo "samebank [0] experiments"
latency -c 0 -i 100 2> /dev/null | grep bandwidth

for cpu in `seq 1 $MAXCPU`; do 
    latency -c $cpu -i 1000000000 >& /dev/null &
    latency -c 0 -i 100 2> /dev/null | grep bandwidth
done	


killall latency	
echo "diffbank B1-15"
echo 0-$MAXCPU > /sys/fs/cgroup/corun_diffbank/cpuset.cpus
echo 1-15 > /sys/fs/cgroup/corun_diffbank/phalloc.bins

echo $$ > /sys/fs/cgroup/corun_samebank/tasks
latency -c 0 -i 100 2> /dev/null | grep bandwidth

for cpu in `seq 1 $MAXCPU`; do 
    echo $$ > /sys/fs/cgroup/corun_diffbank/tasks
    latency -c $cpu -i 1000000000 >& /dev/null &
    echo $$ > /sys/fs/cgroup/corun_samebank/tasks
    latency -c 0 -i 100 2> /dev/null | grep bandwidth
done


killall latency	
echo "diffbank B1"
echo 0-$MAXCPU > /sys/fs/cgroup/corun_diffbank/cpuset.cpus
echo 1 > /sys/fs/cgroup/corun_diffbank/phalloc.bins

echo $$ > /sys/fs/cgroup/corun_samebank/tasks
latency -c 0 -i 100 2> /dev/null | grep bandwidth


for cpu in `seq 1 $MAXCPU`; do 
    echo $$ > /sys/fs/cgroup/corun_diffbank/tasks
    latency -c $cpu -i 1000000000 >& /dev/null &
    echo $$ > /sys/fs/cgroup/corun_samebank/tasks
    latency -c 0 -i 100 2> /dev/null | grep bandwidth
done
killall latency	

echo "buddy experiments"
echo $$ > /sys/fs/cgroup/tasks
latency -c 0 -i 100 2> /dev/null | grep bandwidth

for cpu in `seq 1 $MAXCPU`; do 
    latency -c $cpu -i 1000000000 >& /dev/null &
    latency -c 0 -i 100 2> /dev/null | grep bandwidth
done



