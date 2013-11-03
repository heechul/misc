#!/bin/bash
#
# Detect bank and rank bits
#
# (c) 2013 Heechul Yun <heechul@ittc.ku.edu>
#

killall -9 mc-mapping

if ! mount | grep hugetlbfs; then
    echo "run init-hugetlfs.sh"
    exit 1
fi

echo "Run a background task on core1"
for cpu in 1 2 3; do
    ./mc-mapping -c $cpu -i 100000000000 >& /dev/null &
done

sleep 1

echo "Now run the test"
for b in `seq 6 20`; do 
    echo -n "Bit$b: "
    ./mc-mapping -c 0 -i 5000000 -o 1 -b $b 2> /dev/null | grep band | awk '{ print $2 }'
done
killall -9 mc-mapping
