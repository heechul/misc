#!/bin/bash

. ./functions

[ ! -z "$2" ] && outputfile=$2

echo "LLC miss evt: 0x${llc_miss_evt}"
echo "arch bit: ${archbit}bit"
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

parse_log_instr()
{
    f=$1
    if [ -f "$f" ]; then
	instr=`grep instructions $f | awk '{ print $1 }' | sed "s/,//g"`
	echo $instr
    fi
}

parse_log_XXX()
{
    f=$1
    counter=$2
    if [ -f "$f" ]; then
	instr=`grep $counter $f | awk '{ print $1 }' | sed "s/,//g"`
	echo $instr
    fi
}

# do experiment
do_experiment_solo()
{
    if [ `whoami` != "root" ]; then
	error "root perm. is needed"
    fi

    # chrt -f -p 1 $$

    for b in $benchb; do
	# echo $b
	echo "" > /sys/kernel/debug/tracing/trace
	echo "flush" > /sys/kernel/debug/palloc/control
	echo 1 > /proc/sys/vm/drop_caches # free file caches
	taskset -c $corea perf stat -e r$llc_miss_evt:u,instructions:u -e r80b0 -e r01b2 -o $b.perf /ssd/cpu2006/bin/specinvoke -d /ssd/cpu2006/benchspec/CPU2006/$b/run/run_base_ref_gcc43-${archbit}bit.0000 -e speccmds.err -o speccmds.stdout -f speccmds.cmd -C -q &
	sleep 10
	kill_spec >& /dev/null
	cat /sys/kernel/debug/tracing/trace > $b.trace
	IX=`parse_log_instr $b.perf`
	IX="$IX `parse_log_XXX $b.perf 412e` `parse_log_XXX $b.perf 80b0` `parse_log_XXX $b.perf 1b2`"
	log_echo $b $IX
	sync
    done
}

# do experiment
do_experiment()
{
    if [ `whoami` != "root" ]; then
	error "root perm. is needed"
    fi

    # chrt -f -p 1 $$

    echo "bench C0 C1 C2 C3 SUM"
    for b in $benchb; do
	#echo $b
	echo "" > /sys/kernel/debug/tracing/trace
	echo "flush" > /sys/kernel/debug/palloc/control
	echo 1 > /sys/kernel/debug/palloc/debug_level
	echo 1 > /proc/sys/vm/drop_caches # free file caches


	echo $$ > /sys/fs/cgroup/core1/tasks; run_bench 470.lbm 1 &
	echo $$ > /sys/fs/cgroup/core2/tasks; run_bench 470.lbm 2 &
	echo $$ > /sys/fs/cgroup/core3/tasks; run_bench 470.lbm 3 &
	echo $$ > /sys/fs/cgroup/spec2006/tasks

	taskset -c $corea perf stat -e r$llc_miss_evt:u,instructions:u -o $b.perf /ssd/cpu2006/bin/specinvoke -d /ssd/cpu2006/benchspec/CPU2006/$b/run/run_base_ref_gcc43-${archbit}bit.0000 -e speccmds.err -o speccmds.stdout -f speccmds.cmd -C -q &
	sleep 10
	kill_spec >& /dev/null
	cat /sys/kernel/debug/tracing/trace > $b.trace
	
	I0=`parse_log_instr $b.perf`
	I1=`parse_log_instr C1.470.lbm.perf`
	I2=`parse_log_instr C2.470.lbm.perf`
	I3=`parse_log_instr C3.470.lbm.perf`
	IX=`expr $I0 + $I1 + $I2 + $I3`
	log_echo $b $I0 $I1 $I2 $I3 $IX
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
benchb="$spec2006_xeon_rta13"
# benchb=436.cactusADM
#benchb="470.lbm"
# benchb=462.libquantum
init_system
set_cpus "1 1 1 1"
# enable_prefetcher >> profile.txt
# do_init "100,100,100,100"
corea=0
mode=$1

[ -z "$mode" ] && error "Usage: $0 <solo|corun>"

print_sysinfo

if [ "$mode" = "corun" ]; then
    do_experiment    
else
    do_experiment_solo
    do_graph
    do_print_stat >> bench.stat
fi


