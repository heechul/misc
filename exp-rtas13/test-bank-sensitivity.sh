#!/bin/bash

. functions

outputfile=profile.txt

repeat=1
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

log_echo '4_bank(1rankx4bank)'
for i in `seq 1 $repeat`; do
echo 0    > /sys/fs/cgroup/spec2006/phdusa.dram_rank
echo 0-3  > /sys/fs/cgroup/spec2006/phdusa.dram_bank
echo $$ > /sys/fs/cgroup/spec2006/tasks
echo 2 > /sys/kernel/debug/color_page_alloc/debug_level
./profile.sh 0
done

log_echo '4_bank(4rankx1bank)'
for i in `seq 1 $repeat`; do
echo 0-3  > /sys/fs/cgroup/spec2006/phdusa.dram_rank
echo 0    > /sys/fs/cgroup/spec2006/phdusa.dram_bank
echo $$ > /sys/fs/cgroup/spec2006/tasks
echo 2 > /sys/kernel/debug/color_page_alloc/debug_level
./profile.sh 0
done

exit

log_echo buddy
echo 99 > /sys/kernel/color_page_alloc/debug_level
./profile.sh 0


