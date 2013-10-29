#!/bin/bash

. functions

outputfile=profile.txt

repeat=1

# [000X] = 0,1    18,233,825,295  
# [00X0] = 0,2    16,562,773,721 
# [0X00] = 0,4    19,838,819,062  <-diff rank (?)
# [X000] = 0,8    17,620,918,273

set_cgroup_bins()
{
    bins=$1
    balance=$2
    log_echo "4B-[$bins]-($balance)"
    echo $bins  > /sys/fs/cgroup/spec2006/palloc.bins
    echo $$ > /sys/fs/cgroup/spec2006/tasks
    echo 2 > /sys/kernel/debug/palloc/debug_level
    echo $balance > /sys/kernel/debug/palloc/alloc_balance
}

balance=0
log_echo 'buddy-solo'
echo 99 > /sys/kernel/debug/palloc/debug_level
./profile.sh 0

log_echo '4B-LO-solo($balance)'
set_cgroup_bins "0-3" $balance
./profile.sh 0

log_echo '8B-LO-solo($balance)'
set_cgroup_bins "0-7" $balance
./profile.sh 0

log_echo '16B-LO-solo($balance)'
set_cgroup_bins "0-15" $balance
./profile.sh 0
