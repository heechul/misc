#!/bin/bash

# .bash_profile. ~/.bash_profile
. ./functions

PATH=$PATH:..

outputfile=profile.txt
repeat=1

log_echo "============================="
date >> $outputfile
uname -a >> $outputfile
log_echo "============================="


[ -d "/sys/fs/cgroup/core1" ] || error "core1 cgroup does not exist"

echo 1 > /sys/kernel/debug/palloc/use_palloc
echo 2 > /sys/kernel/debug/palloc/debug_level
echo 0 > /sys/kernel/debug/palloc/alloc_balance
echo $$ > /sys/fs/cgroup/tasks

log_echo "SPEC vs. 3xbandwidth"
log_echo 'PB+PC'

cleanup()
{
    echo "" > /sys/kernel/debug/tracing/trace
    echo "flush" > /sys/kernel/debug/palloc/control
    killall bandwidth >& /dev/null
}

runspecbench_buddy()
{
    bench="$1"
    cmd="$2"
    corun="$3"

    echo $$ > /sys/fs/cgroup/tasks

    if [ "$corun" = "corun" ]; then
	cpu=1
	for bins in "1" "2" "3"; do
	    bandwidth -c $cpu -a write -t 1000000 &
	    cpu=`expr $cpu + 1`
	done >& /dev/null
    fi

    pushd $SPECBASE/$bench/run/run_base_ref_gcc43-64bit.0000  > /dev/null
    cmd_full="perf stat -e r$llc_miss_evt,cycles $cmd"
    bash -c "$cmd_full" >& /tmp/tmplog

    cleanup
    elapsed=`grep elapsed /tmp/tmplog | awk '{ print $1 }'`
    misses=`grep $llc_miss_evt /tmp/tmplog | awk '{ print $1 }'`
    popd  > /dev/null

    log_echo $bench $misses $elapsed $corun
}


runspecbench()
{
    bench="$1"
    cmd="$2"
    corun="$3"

    if [ "$corun" = "corun" ]; then
	cpu=1
	for bins in "1" "2" "3"; do
	    echo $bins > /sys/fs/cgroup/core$cpu/palloc.bins
	    echo $$ > /sys/fs/cgroup/core$cpu/tasks
	    bandwidth -c $cpu -a write -t 1000000 &
	    cpu=`expr $cpu + 1`
	done >& /dev/null
    fi

    echo 0 > /sys/fs/cgroup/spec2006/palloc.bins
    echo $$ > /sys/fs/cgroup/spec2006/tasks

    pushd $SPECBASE/$bench/run/run_base_ref_gcc43-64bit.0000  > /dev/null
    cmd_full="perf stat -e r$llc_miss_evt,cycles $cmd"
    bash -c "$cmd_full" >& /tmp/tmplog

    cleanup
    elapsed=`grep elapsed /tmp/tmplog | awk '{ print $1 }'`
    misses=`grep $llc_miss_evt /tmp/tmplog | awk '{ print $1 }'`
    popd  > /dev/null

    log_echo $bench $misses $elapsed $corun
}

SPECBASE=/ssd/cpu2006/benchspec/CPU2006
for i in `seq 1 $repeat`; do
    # runbench 470.lbm "./lbm_base.gcc43-64bit 60 reference.dat 0 0 100_100_130_ldc.of" # 9.9s

    # runspecbench 462.libquantum "./libquantum_base.gcc43-64bit 244 8" solo # 4.146s
    # runspecbench 462.libquantum "./libquantum_base.gcc43-64bit 244 8" corun # 4.146s

    # runspecbench 482.sphinx3 "./sphinx_livepretend_base.gcc43-64bit ctlfile_small . args.an4" solo
    # runspecbench 482.sphinx3 "./sphinx_livepretend_base.gcc43-64bit ctlfile_small . args.an4" corun

    # runspecbench_buddy 450.soplex "./soplex_base.gcc43-64bit -m500 pds-50.mps" solo
    # runspecbench_buddy 450.soplex "./soplex_base.gcc43-64bit -m500 pds-50.mps" corun

    # runspecbench 450.soplex "./soplex_base.gcc43-64bit -m500 pds-50.mps" solo
    # runspecbench 450.soplex "./soplex_base.gcc43-64bit -m500 pds-50.mps" corun

    # runspecbench 483.xalancbmk "./Xalan_base.gcc43-64bit -v t5.xml xalanc.xsl" solo
    # runspecbench 483.xalancbmk "./Xalan_base.gcc43-64bit -v t5.xml xalanc.xsl" corun

    runspecbench 403.gcc "./gcc_base.gcc43-64bit scilab.in -o scilab.s" solo
    runspecbench 403.gcc "./gcc_base.gcc43-64bit scilab.in -o scilab.s" corun
done


sudo killall bandwidth
chown heechul.heechul profile.txt
