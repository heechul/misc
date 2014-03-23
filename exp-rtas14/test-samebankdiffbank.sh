#!/bin/bash

. ./functions # MAXCPU, SYSTEM

PATH=$PATH:..

killall -9 latency 

outputfile=log.txt

if [ ! -d "/sys/fs/cgroup/corun_samebank" ]; then
    echo "run init-spec2006-cgroup.sh"
    exit
fi
echo 0-$MAXCPU > /sys/fs/cgroup/corun_samebank/cpuset.cpus
echo 0 > /sys/fs/cgroup/corun_samebank/cpuset.mems
echo 0 > /sys/fs/cgroup/corun_samebank/palloc.bins
echo $$ > /sys/fs/cgroup/corun_samebank/tasks

echo 1 > /sys/kernel/debug/palloc/use_palloc
echo 2 > /sys/kernel/debug/palloc/debug_level


killall latency	
log_echo "samebank [0] experiments"
output=`latency -m 32768 -c  0 -i 100 2> /dev/null | grep bandwidth`
log_echo $output

for cpu in `seq 1 $MAXCPU`; do 
    latency -m 32768 -c  $cpu -i 1000000000 >& /dev/null &
    output=`latency -m 32768 -c  0 -i 100 2> /dev/null | grep bandwidth`
    log_echo $output
done	


killall latency	
log_echo "diffbank B1-15"
echo 0-$MAXCPU > /sys/fs/cgroup/corun_diffbank/cpuset.cpus
echo 1-15 > /sys/fs/cgroup/corun_diffbank/palloc.bins

echo $$ > /sys/fs/cgroup/corun_samebank/tasks
output=`latency -m 32768 -c  0 -i 100 2> /dev/null | grep bandwidth`
log_echo $output

for cpu in `seq 1 $MAXCPU`; do 
    echo $$ > /sys/fs/cgroup/corun_diffbank/tasks
    latency -m 32768 -c  $cpu -i 1000000000 >& /dev/null &
    echo $$ > /sys/fs/cgroup/corun_samebank/tasks
    output=`latency -m 32768 -c  0 -i 100 2> /dev/null | grep bandwidth`
    log_echo $output
done


killall latency	
log_echo "diffbank B1"
echo 0-$MAXCPU > /sys/fs/cgroup/corun_diffbank/cpuset.cpus
echo 1 > /sys/fs/cgroup/corun_diffbank/palloc.bins

echo $$ > /sys/fs/cgroup/corun_samebank/tasks
output=`latency -m 32768 -c  0 -i 100 2> /dev/null | grep bandwidth`
log_echo $output

for cpu in `seq 1 $MAXCPU`; do 
    echo $$ > /sys/fs/cgroup/corun_diffbank/tasks
    latency -m 32768 -c  $cpu -i 1000000000 >& /dev/null &
    echo $$ > /sys/fs/cgroup/corun_samebank/tasks
    output=`latency -m 32768 -c  0 -i 100 2> /dev/null | grep bandwidth`
    log_echo $output
done
killall latency	

log_echo "buddy experiments"
echo $$ > /sys/fs/cgroup/tasks
output=`latency -m 32768 -c  0 -i 100 2> /dev/null | grep bandwidth`
log_echo $output

for cpu in `seq 1 $MAXCPU`; do 
    latency -m 32768 -c  $cpu -i 1000000000 >& /dev/null &
    output=`latency -m 32768 -c  0 -i 100 2> /dev/null | grep bandwidth`
    log_echo $output
done



killall latency	
