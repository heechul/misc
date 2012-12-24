#!/bin/sh

cd /sys/kernel/debug/color_page_alloc
echo 0 1 0 > core
echo 1 1 1 > core
echo 2 1 0 > core
echo 3 1 1 > core
echo 2 > colors
echo 1 > enable
