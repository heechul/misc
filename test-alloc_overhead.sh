
echo 1 > /sys/fs/cgroup/core1/cpuset.cpus
echo 0 > /sys/fs/cgroup/core1/phdusa.dram_bank
echo 0 > /sys/fs/cgroup/core1/phdusa.dram_rank
echo 0 > /sys/fs/cgroup/core1/phdusa.colors
echo $$ > /sys/fs/cgroup/core1/tasks
echo 99 > /sys/kernel/debug/color_page_alloc/debug_level
for rank in "0,1,2,3"; do
    echo $rank > /sys/fs/cgroup/core1/phdusa.dram_rank
    echo "Rank: $rank"
    for mb in 1 1 2 4 8 16 32 64 128 256 512; do
	echo "flush" > /sys/kernel/debug/color_page_alloc/control
	echo "reset" > /sys/kernel/debug/color_page_alloc/control
	kb=`expr $mb \* 1024`
	./latency -m $kb >& /dev/null
	cat /sys/kernel/debug/color_page_alloc/control > ohd-$mb.stat
	echo -n "$mb MB: "
    # color
	stat_color=`grep tot_cnt ohd-$mb.stat | head -n 1 | awk '{ print $2 " " $3 " " $4 " " $5 }'`
	rate=`grep rate ohd-$mb.stat | head -n 1 | awk '{ print $4 }' | sed 's/(//'`
	# echo $stat $rate
    # normal
	stat_normal=`grep tot_cnt ohd-$mb.stat | head -n 2 | tail -n 1 | awk '{ print $2 " " $3 " " $4 " " $5 }'`
	echo $stat_normal
    done
done

exit
echo "Normal"
for mb in 1 1 2 4 8 16 32 64 128; do
    echo -n "$mb MB: "

done