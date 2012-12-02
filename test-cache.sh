#!/bin/bash

./bandwidth 8192 write 10 3 &
./bandwidth 512 rdwr 1 1
echo "core1"
./bandwidth 512 rdwr 2 1
echo "core2"
./bandwidth 512 rdwr 2 2
