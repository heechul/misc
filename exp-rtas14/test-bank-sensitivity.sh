#!/bin/bash

. functions

outputfile=profile.txt

repeat=1

# [000X] = 0,1    18,233,825,295  
# [00X0] = 0,2    16,562,773,721 
# [0X00] = 0,4    19,838,819,062  <-diff rank (?)
# [X000] = 0,8    17,620,918,273

set_cgroup_bank_rank()
{
    hi=$1
    lo=$2
    balance=$3
    log_echo "1B-[$hi]-[$lo]-($balance)"
    echo $hi  > /sys/fs/cgroup/spec2006/phdusa.dram_bank
    echo $lo  > /sys/fs/cgroup/spec2006/phdusa.dram_rank
    echo $$ > /sys/fs/cgroup/spec2006/tasks
    echo 2 > /sys/kernel/debug/color_page_alloc/debug_level
    echo $balance > /sys/kernel/debug/color_page_alloc/alloc_balance
}

balance=2
set_cgroup_bank_rank "0" "0,1"  $balance
./profile.sh 0
set_cgroup_bank_rank "0" "0,2"  $balance
./profile.sh 0
set_cgroup_bank_rank "0,1" "0"  $balance
./profile.sh 0
set_cgroup_bank_rank "0,2" "0"  $balance
./profile.sh 0

exit

for balance in 4 3 2 1 0; do 
    set_cgroup_bank_rank "0" "0-3"  $balance
    ./profile.sh 0

    set_cgroup_bank_rank "0-3" "0"  $balance
    ./profile.sh 0
done


exit


log_echo '4B-HI'
for i in `seq 1 $repeat`; do
echo 0    > /sys/fs/cgroup/spec2006/phdusa.dram_rank
echo 0-3  > /sys/fs/cgroup/spec2006/phdusa.dram_bank
echo $$ > /sys/fs/cgroup/spec2006/tasks
echo 2 > /sys/kernel/debug/color_page_alloc/debug_level
./profile.sh 0
done

log_echo '4B-LO(0)'
for i in `seq 1 $repeat`; do
echo 0-3  > /sys/fs/cgroup/spec2006/phdusa.dram_rank
echo 0    > /sys/fs/cgroup/spec2006/phdusa.dram_bank
echo $$ > /sys/fs/cgroup/spec2006/tasks
echo 2 > /sys/kernel/debug/color_page_alloc/debug_level
./profile.sh 0
done
exit
log_echo 16_bank
for i in `seq 1 $repeat`; do
echo 0-3 > /sys/fs/cgroup/spec2006/phdusa.dram_rank
echo 0-3 > /sys/fs/cgroup/spec2006/phdusa.dram_bank
echo $$ > /sys/fs/cgroup/spec2006/tasks
echo 2 > /sys/kernel/debug/color_page_alloc/debug_level
./profile.sh 0
done

log_echo '8_bank(2rankx4bank)'
for i in `seq 1 $repeat`; do
echo 0-1 > /sys/fs/cgroup/spec2006/phdusa.dram_rank
echo 0-3 > /sys/fs/cgroup/spec2006/phdusa.dram_bank
echo $$ > /sys/fs/cgroup/spec2006/tasks
echo 2 > /sys/kernel/debug/color_page_alloc/debug_level
./profile.sh 0
done

log_echo '8_bank(4rankx2bank)'
for i in `seq 1 $repeat`; do
echo 0-3 > /sys/fs/cgroup/spec2006/phdusa.dram_rank
echo 0-1 > /sys/fs/cgroup/spec2006/phdusa.dram_bank
echo $$ > /sys/fs/cgroup/spec2006/tasks
echo 2 > /sys/kernel/debug/color_page_alloc/debug_level
./profile.sh 0
done

log_echo buddy
echo 99 > /sys/kernel/color_page_alloc/debug_level
./profile.sh 0



for hi in 0 1 2 3; do
    for lo in 0 1 2 3; do
	log_echo "1B-$hi-$lo"
	echo $lo  > /sys/fs/cgroup/spec2006/phdusa.dram_rank
	echo $hi  > /sys/fs/cgroup/spec2006/phdusa.dram_bank
	echo $$ > /sys/fs/cgroup/spec2006/tasks
	echo 2 > /sys/kernel/debug/color_page_alloc/debug_level
	./profile.sh 0
    done
done

