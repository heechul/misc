#!/bin/bash

. functions
. ~/.bash_profile

outputfile=profile.txt
repeat=1

echo done > DONE
kill_spec
sleep 1
rm -f DONE

log_echo '8B-diffbank-HI-w/lbm'
echo 2,3 > /sys/fs/cgroup/corun_diffbank/phdusa.dram_rank
echo 0-3 > /sys/fs/cgroup/corun_diffbank/phdusa.dram_bank
echo $$ > /sys/fs/cgroup/corun_diffbank/tasks
echo 2 > /sys/kernel/debug/color_page_alloc/debug_level
./profile-corun-lbm.sh &

echo 0,1 > /sys/fs/cgroup/spec2006/phdusa.dram_rank
echo 0-3 > /sys/fs/cgroup/spec2006/phdusa.dram_bank
echo $$ > /sys/fs/cgroup/spec2006/tasks
for i in `seq 1 $repeat`; do
    ./profile.sh 0
done

echo done > DONE
kill_spec
sleep 1

log_echo '8B-diffbank-LO-w/lbm'
echo 0-3 > /sys/fs/cgroup/corun_diffbank/phdusa.dram_rank
echo 0,1 > /sys/fs/cgroup/corun_diffbank/phdusa.dram_bank
echo $$ > /sys/fs/cgroup/corun_diffbank/tasks
echo 2 > /sys/kernel/debug/color_page_alloc/debug_level
./profile-corun-lbm.sh &

echo 0-3 > /sys/fs/cgroup/spec2006/phdusa.dram_rank
echo 2,3 > /sys/fs/cgroup/spec2006/phdusa.dram_bank
echo $$ > /sys/fs/cgroup/spec2006/tasks
for i in `seq 1 $repeat`; do
    ./profile.sh 0
done

echo done > DONE
kill_spec
sleep 1

exit

log_echo '8B-samebank-HI-w/lbm'
echo 0,1 > /sys/fs/cgroup/corun_samebank/phdusa.dram_rank
echo 0-3 > /sys/fs/cgroup/corun_samebank/phdusa.dram_bank
echo $$ > /sys/fs/cgroup/corun_samebank/tasks
echo 2 > /sys/kernel/debug/color_page_alloc/debug_level
./profile-corun-lbm.sh &

echo 0,1 > /sys/fs/cgroup/spec2006/phdusa.dram_rank
echo 0-3 > /sys/fs/cgroup/spec2006/phdusa.dram_bank
echo $$ > /sys/fs/cgroup/spec2006/tasks
for i in `seq 1 $repeat`; do
    ./profile.sh 0
done

echo done > DONE
kill_spec

exit
echo 99 > /sys/kernel/debug/color_page_alloc/debug_level
log_echo "SPEC vs. SPEC"
log_echo 'corun-vanilla'
./profile-corun-lbm.sh &
for i in `seq 1 $repeat`; do
    ./profile.sh 0
done

