#!/bin/bash

#
# Test isolation performance of coloring.
#
# solo: run lat_mem_rd on Core 0
# co-run: solo + run bandwidth on Core 2
#

CORE_BENCH=0
CORE_CORUN=1

. functions

LOG=log.exp2.txt

init_log $LOG

[ -f "/sys/fs/cgroup/core0/tasks" ] || ./init-cgroup.sh

bench()
{
    DATFILE=$1
    sleep 1
    ./lat_mem_rd -t 32 2> tmpfile
    tail -n +2 tmpfile > $DATFILE
}

corun()
{
    wsize=$1
    sleep 1
    ./bandwidth -m $wsize -t 10000
}

sync()
{
    sleep $1
    killall -9 lat_mem_rd bandwidth >& /dev/null
}

plot()
{
    cat > exp2.scr <<EOF
set terminal postscript eps enhanced mono "Times-Roman" 20
set xtics nomirror rotate by -90 scale 0 font ",16"
set key top left
plot 'exp2-solo.dat' using 2:xtic(1) w lp ti "solo", \
 'exp2-corun-bw10m.dat' using 2:xtic(1) w lp ti "corun-bandwidth(10m)"

EOF
    gnuplot exp2.scr > exp2.eps
    epspdf  exp2.eps
}

echo_log "color: solo"
bench exp2-solo.dat &
echo $! > /sys/fs/cgroup/core${CORE_BENCH}/tasks
echo "bench: pid=$!"
sync 50

echo_log "color: co-run w/ bandwidth(10m)"
corun 10000 &
echo $! > /sys/fs/cgroup/core${CORE_CORUN}/tasks
echo "corun: pid=$!"

bench exp2-corun-bw10m.dat &
echo $! > /sys/fs/cgroup/core0/tasks
echo "bench: pid=$!"
sync 50

plot
