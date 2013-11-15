#!/bin/bash

mount -t hugetlbfs none /mnt/huge
echo 512 > /proc/sys/vm/nr_hugepages

