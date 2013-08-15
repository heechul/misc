while true; do
    echo 1 > /proc/sys/vm/drop_caches
    echo reset > /sys/kernel/debug/color_page_alloc/control
    echo flush > /sys/kernel/debug/color_page_alloc/control
    echo "Press any key to start:"
    read
    ./latency 
    cat /sys/kernel/debug/color_page_alloc/control
done