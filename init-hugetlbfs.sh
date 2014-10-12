#!/bin/bash

mount | grep hugetlbfs || mount -t hugetlbfs none /mnt/huge
echo 2048 > /proc/sys/vm/nr_hugepages

