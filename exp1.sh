#!/bin/bash

CORE_BENCH=0
CORE_CORUN=1

. functions

LOG=log.exp1.txt

init_log $LOG

bench()
{
    DATFILE=$1

    taskset -c $CORE_BENCH ./lat_mem_rd -t 32 2> tmpfile
    tail -n +2 tmpfile > $DATFILE

    killall -9 bandwidth >& /dev/null
}

corun()
{
    wsize=$1
    ./bandwidth -c $CORE_CORUN -m $wsize -t 10000 &
}


plot()
{
    cat > exp1.scr <<EOF
set terminal postscript eps enhanced mono "Times-Roman" 20
set xtics nomirror rotate by -90 scale 0 font ",16"
set key top left
plot 'exp1-solo.dat' using 2:xtic(1) w lp ti "solo", \
 'exp1-corun-bw512k.dat' using 2:xtic(1) w lp ti "corun-bandwidth(512k)",\
 'exp1-corun-bw1m.dat' using 2:xtic(1) w lp ti "corun-bandwidth(1m)",\
 'exp1-corun-bw2m.dat' using 2:xtic(1) w lp ti "corun-bandwidth(2m)",\
 'exp1-corun-bw10m.dat' using 2:xtic(1) w lp ti "corun-bandwidth(10m)"

EOF
    gnuplot exp1.scr > exp1.eps
    epspdf  exp1.eps
}

echo_log "solo"
bench exp1-solo.dat

echo_log "co-run w/ bandwidth(512)"
corun 512
bench exp1-corun-bw512k.dat

echo_log "co-run w/ bandwidth(1m)"
corun 1000
bench exp1-corun-bw1m.dat

echo_log "co-run w/ bandwidth(2m)"
corun 2000
bench exp1-corun-bw2m.dat

echo_log "co-run w/ bandwidth(10m)"
corun 10000
bench exp1-corun-bw10m.dat

plot
