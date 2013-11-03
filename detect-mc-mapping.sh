#!/bin/bash
killall -9 mc-mapping
echo "Run a background task on core1"
./mc-mapping -c 1 -i 100000000000 -x >& /dev/null &
./mc-mapping -c 2 -i 100000000000 -x >& /dev/null &
./mc-mapping -c 3 -i 100000000000 -x >& /dev/null &
sleep 1

echo "Now run the test"
for b in `seq 6 30`; do 
	echo -n "Bit$b: "
	./mc-mapping -c 0 -i 5000000 -o 1 -b $b -x 2> /dev/null | grep band | awk '{ print $2 }' || echo "N/A"
done
killall -9 mc-mapping
