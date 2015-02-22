#!/bin/bash

. ./functions

echo "LLC miss evt: 0x${llc_miss_evt}"
echo "arch bit: ${archbit}bit"

# r2a2 load buffer full
# r4a2 RS full
# r8a2 store buffer full
# r10a2 ROB full
# perf_hwevents="instructions r2a2 r4a2 r8a2 r10a2"

# L3 miss, L2 miss, resource stall, SQ stall
perf_hwevents="instructions r412e raa24 r1a2 r1f6"

# GQ statistics 
# uncore/event=0x00,umask=0x01  GQ read full
# uncore/event=0x00,umask=0x02  GQ write full

# uncore/event=0x01,umask=0x01  GQ RT not empty 

# uncore/event=0x02,umask=0x01  GQ RT occupancy
# uncore/event=0x02,umask=0x02  GQ RT llc miss occupancy
# uncore/event=0x02,umask=0x20  GQ WT occupancy

# uncore/event=0x03,umask=0x01  GQ RT alloc cnt
# uncore/event=0x03,umask=0x02  GQ RT llc miss alloc
# uncore/event=0x03,umask=0x20  GQ WT alloc cnt

# uncore/event=0x2a,umask=0x01  GQ IMC ch0 read occupancy
# uncore/event=0x62,umask=0x01  GQ DRAM ch0 row miss

# uncore/event=0x0b,umask=0x01  UNC_L3_LINES_OUT.M_STATE 

perf_hwevents_unc="uncore/event=0x0b,umask=0x01/ uncore/event=0x2C,umask=0x07/ uncore/event=0x2F,umask=0x07/"
# perf_hwevents_unc="uncore/event=0x0b,umask=0x01/ uncore/event=0x01,umask=0x01/ uncore/event=0x02,umask=0x01/ uncore/event=0x03,umask=0x01/ uncore/event=0x02,umask=0x02/ uncore/event=0x03,umask=0x02/ uncore/event=0x2a,umask=0x04/ uncore/event=0x62,umask=0x04/"

# DRAM statistics
# UNC_QMC_NORMAL_READS.ANY IMC normal read requests  07 2C   (umask, evt)
# UNC_QMC_WRITES.FULL.ANY IMC full cache line writes 07 2F
# UNC_DRAM_OPEN.CH2 DRAM Channel 2 open commands    04 60
# UNC_DRAM_PAGE_CLOSE.CH2 DRAM Channel 2 page close  04 61
# UNC_DRAM_PAGE_MISS.CH2 DRAM Channel 2 page miss    04 62
# UNC_DRAM_READ_CAS.CH2  DRAM Channel 2 read CAS     10 63
# UNC_DRAM_WRITE_CAS.CH2 DRAM Channel 2 write CAS   10 64
# perf_hwevents_unc="uncore/event=0x2C,umask=0x07/ uncore/event=0x2F,umask=0x07/ uncore/event=0x60,umask=0x04/ uncore/event=0x61,umask=0x04/ uncore/event=0x62,umask=0x04/ uncore/event=0x63,umask=0x10/ uncore/event=0x64,umask=0x10/"

# additional DRAM statistics
# UNC_QMC_NORMAL_FULL.READ.CH2 read request queue full   04 27
# UNC_QMC_NORMAL_FULL.WRITE.CH2 write request queue full 20 27
# UNC_QMC_OCCUPANCY.CH2  read request occupancy          04 2A
# 
# average DRAM read req latency = 
#   UNC_QMC_OCCUPANCY.CH2 / UNC_QMC_NORMAL_FULL.READ.CH2
# 
get_perf_hwevent_str()
{
    local str=""
    for evt in $perf_hwevents; do
	str="$str -e ${evt}:u"
    done
    echo "$str"
}

get_perf_hwevent_unc_str()
{
    local str=""
    for evt in $perf_hwevents_unc; do
	str="$str -e ${evt}"
    done
    echo "$str"
}

parse_perf_log()
{
    f=$1
    val=`grep elapsed $f | awk '{ print $1 }' | sed "s/,//g"`
    if [ -f "$f" ]; then
	for counter in $perf_hwevents; do
	    [[ $counter == r* ]] && cstr=${counter:1} || cstr=$counter
	    val="$val `grep $cstr $f | awk '{ print $1 }' | sed "s/,//g"`"
	done
    fi
    echo $val
}

parse_uncore_log()
{
    f=$1
    val=`grep attr $f | awk '{ print $1 }' | sed "s/,//g"`
    echo $val
}

set_buddy()
{
    PALLOC_MODE="buddy"
    log_echo $PALLOC_MODE
    echo 0 > /sys/kernel/debug/palloc/use_palloc
    echo "flush" > /sys/kernel/debug/palloc/control
}

set_pbpc()
{
    set_buddy

    PALLOC_MODE="PB+PC"
    log_echo $PALLOC_MODE
    set_cgroup_bins spec2006 "0"
    set_cgroup_bins core1 "1"
    set_cgroup_bins core2 "2"
    set_cgroup_bins core3 "3"
    echo 1 > /sys/kernel/debug/palloc/use_palloc
    echo 2 > /sys/kernel/debug/palloc/debug_level
    echo 4 > /sys/kernel/debug/palloc/alloc_balance
}

set_cgroup_bins()
{
    cg="$1"
    bins="$2"
    log_echo "Bins[$bins]"
    echo 250000000 > /sys/fs/cgroup/$cg/memory.limit_in_bytes || error "No cgroup $cg"
    echo $bins  > /sys/fs/cgroup/$cg/palloc.bins || error "Bins $bins error"
    echo $$ > /sys/fs/cgroup/$cg/tasks

    echo 0-$MAXCPU > /sys/fs/cgroup/$cg/cpuset.cpus
    echo 0 > /sys/fs/cgroup/$cg/cpuset.mems
}

plot()
{
    # file msut be xxx.dat form
    bench=$1
    start=$2
    finish=$3
    file="${bench}_${start}-${finish}"
    cat > ${file}.scr <<EOF
set terminal postscript eps enhanced color "Times-Roman" 22
set yrange [0:100000]
set xrange [$start:$finish]
plot '$bench.dat' ti "$bench" w l
EOF
    gnuplot ${file}.scr > ${file}.eps
    epspdf  ${file}.eps
}


# do experiment
do_experiment_solo()
{
    local runcmd
    if [ `whoami` != "root" ]; then
	error "root perm. is needed"
    fi

    # chrt -f -p 1 $$

    echo "bench inst elapsed llc l2 rob gq"
    for b in $benchb; do
	# echo $b
	echo "" > /sys/kernel/debug/tracing/trace
	echo "flush" > /sys/kernel/debug/palloc/control
	echo 1 > /proc/sys/vm/drop_caches # free file caches

	echo $$ > /sys/fs/cgroup/spec2006/tasks
	kill_spec
	taskset -c 1 perf stat -o $b.uncore.solo -a `get_perf_hwevent_unc_str` sleep 8000 &
	if [ "$b" = "bw_write_1M" ]; then
	    runcmd="./bandwidth -m 1024 -t 1000000 -i 30000 -a write"
	elif [ "$b" = "bw_write_16M" ]; then
	    runcmd="./bandwidth -m 16384 -t 1000000 -i 3000 -a write"
	elif [ "$b" = "bw_read_1M" ]; then
	    runcmd="./bandwidth -m 1024 -t 1000000 -i 30000 -a read"
	elif [ "$b" = "bw_read_16M" ]; then
	    runcmd="./bandwidth -m 16384 -t 1000000 -i 3000 -a read"
	elif [ "$b" = "latency_1M" ]; then
	    runcmd="./latency -m 1024 -i 5000"
	elif [ "$b" = "latency_16M" ]; then
	    runcmd="./latency -m 16384 -i 100"
	else
	    runcmd="/ssd/cpu2006/bin/specinvoke -d /ssd/cpu2006/benchspec/CPU2006/$b/run/run_base_${workload}_gcc43-${archbit}bit.0000 -e speccmds.err -o speccmds.stdout -f speccmds.cmd -C -q"
	fi
	taskset -c $corea perf stat `get_perf_hwevent_str` -o $b.perf.solo $runcmd
	killall -1 sleep
	sleep 1 
	cat /sys/kernel/debug/tracing/trace > $b.trace
	IX=`parse_perf_log $b.perf.solo`
	IX="$IX `parse_uncore_log $b.uncore.solo`"
	log_echo $b $IX
	sync
    done
}

do_load()
{
    local type=$1
    local size_kb=$2
    log_echo "corun w/ bandwidth -a $type -m $size_kb"
    for cpu in 1 2 3; do 
	echo $$ > /sys/fs/cgroup/core$cpu/tasks
	bandwidth -m $size_kb -a $type -c $cpu -t 1000000000 &
    done
}

# do experiment
do_experiment()
{
    if [ `whoami` != "root" ]; then
	error "root perm. is needed"
    fi

    # chrt -f -p 1 $$

    echo "bench inst elapsed"
    for b in $benchb; do
	#echo $b
	echo "" > /sys/kernel/debug/tracing/trace
	echo "flush" > /sys/kernel/debug/palloc/control
	echo 1 > /sys/kernel/debug/palloc/debug_level
	echo 1 > /proc/sys/vm/drop_caches # free file caches

	do_load $coruntype $corunsize

	echo $$ > /sys/fs/cgroup/spec2006/tasks
	# -e r01b0 -e r02b0 -e r04b0  -e r08b0

	taskset -c 1 perf stat -o $b.uncore.corun -a `get_perf_hwevent_unc_str` sleep 8000 &
	if [ "$b" = "bw_write_1M" ]; then
	    runcmd="./bandwidth -m 1024 -t 1000000 -i 30000 -a write"
	elif [ "$b" = "bw_write_16M" ]; then
	    runcmd="./bandwidth -m 16384 -t 1000000 -i 3000 -a write"
	elif [ "$b" = "bw_read_1M" ]; then
	    runcmd="./bandwidth -m 1024 -t 1000000 -i 30000 -a read"
	elif [ "$b" = "bw_read_16M" ]; then
	    runcmd="./bandwidth -m 16384 -t 1000000 -i 3000 -a read"
	elif [ "$b" = "latency_1M" ]; then
	    runcmd="./latency -m 1024 -i 5000"
	elif [ "$b" = "latency_16M" ]; then
	    runcmd="./latency -m 16384 -i 100"
	else
	    runcmd="/ssd/cpu2006/bin/specinvoke -d /ssd/cpu2006/benchspec/CPU2006/$b/run/run_base_${workload}_gcc43-${archbit}bit.0000 -e speccmds.err -o speccmds.stdout -f speccmds.cmd -C -q"
	fi
	taskset -c $corea perf stat `get_perf_hwevent_str` -o $b.perf.corun $runcmd
	killall -9 bandwidth >& /dev/null
	killall -1 sleep
	cat /sys/kernel/debug/tracing/trace > $b.trace
	sleep 1 
	
	IX=`parse_perf_log $b.perf.corun`
	IX="$IX `parse_uncore_log $b.uncore.corun`"
	log_echo $b $IX
	sync
    done
}


do_graph()
{
    echo "plotting graphs"
    for b in $benchb; do
	if [ -f "$b.trace" ]; then
	    cat $b.trace | grep "$corea\]" > $b.trace.core$corea
	    grep update_statistics $b.trace.core$corea | awk '{ print $7 }' | grep -v 184467440 > $b.dat
	    plot $b 5000 6000
	    plot $b 0 10000
#	    plot $b 0 100000
	else
	    echo "$b.trace doesn't exist"
	fi
    done
}

# print output

# do_print()
# {
#     for b in $benchb; do
#         f=$b.perf
#         if [ -f "$f" ]; then
#                 cache=`grep $llc_miss_evt $f | awk '{ print $1 }'`
#                 instr=`grep instructions $f | awk '{ print $1 }'`
#                 elaps=`grep elapsed $f | awk '{ print $1 }'`
#                 echo ${f%.perf}, $cache, $instr
# 	else
# 	    echo "$b.perf doesn't exist"
#         fi
#     done
# }

do_print_stat()
{
    for b in $benchb; do
	echo Stats for $b:
	./printstat.py $b.dat
	echo
    done
}

print_sysinfo()
{
    echo "Test CPU: $corea"
    echo "Benchmarks: $benchb"
}

# benchb="$midhighmem 470.lbm"
# benchb=429.mcf
# benchb="$allspec2006"
# benchb="462.libquantum 433.milc 434.zeusmp 437.leslie3d"
# benchb="433.milc"

#benchb="429.mcf"
#benchb=$allspec2006sorted
#benchb=$allspec2006sorted_highmiddle
#benchb=464.h264ref
#benchb="401.bzip2 429.mcf 471.omnetpp 473.astar 482.sphinx3 483.xalancbmk"
#benchb="450.soplex 464.h264ref"

# benchb=$spec2006_xeon_all
# benchb="$spec2006_xeon_rta13"
# benchb=436.cactusADM
#benchb="470.lbm"
# benchb=462.libquantum


spec2006_xeon_rtss14="462.libquantum
437.leslie3d
482.sphinx3
450.soplex
483.xalancbmk
403.gcc
471.omnetpp
447.dealII
400.perlbench
445.gobmk
454.calculix
458.sjeng
435.gromacs
456.hmmer
444.namd
464.h264ref
465.tonto
453.povray
416.gamess"

spec2006_xeon_rtas15_sorted="462.libquantum
482.sphinx3
437.leslie3d
471.omnetpp
465.tonto
445.gobmk
456.hmmer
454.calculix
458.sjeng
435.gromacs
464.h264ref
444.namd
416.gamess
453.povray"

spec2006_xeon_rtas15_sorted_hi="462.libquantum
482.sphinx3
437.leslie3d
471.omnetpp
465.tonto"

spec2006_xeon_rtas15_sorted_lo="445.gobmk
456.hmmer
454.calculix
458.sjeng
435.gromacs
464.h264ref
444.namd
416.gamess
453.povray"

# benchb="bw_read_1M"
# benchb="458.sjeng 453.povray 471.omnetpp 462.libquantum"
# benchb="471.omnetpp 462.libquantum"
benchb="$spec2006_xeon_rtas15_sorted"
# benchb="453.povray"
# benchb="$spec2006_xeon_rtss14"
# benchb=445.gobmk
# benchb=456.hmmer
#435.gromacs
#400.perlbench
#464.h264ref
#416.gamess"
# benchb="400.perlbench"

# benchb="445.gobmk 456.hmmer 435.gromacs 464.h264ref 444.namd 416.gamess 453.povray"
# benchb=453.povray

# 450.soplex
#416.gamess
init_system
set_cpus "1 1 1 1"
# enable_prefetcher >> profile.txt
# do_init "100,100,100,100"
corea=0
mode=$1
workload="ref"   # ref | test | train
corunsize=16384
coruntype=read

[ -z "$mode" ] && error "Usage: $0 <solo|corun>"
[ ! -z "$2" ] && outputfile=$2
[ ! -z "$3" ] && workload=$3
[ ! -z "$4" ] && corunsize=$4
[ ! -z "$5" ] && coruntype=$5
[ ! -z "$6" ] && benchb=$6

print_sysinfo
set_pbpc

if [ "$mode" = "corun" ]; then
    do_experiment    
else
    do_experiment_solo
    #do_graph
    #do_print_stat >> bench.stat
fi
