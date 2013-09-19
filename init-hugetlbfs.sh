#!/bin/bash

mount -t hugetlbfs none /mnt/huge
echo 256 > /proc/sys/vm/nr_hugepages

