msize=$1

[ -z "$msize" ] && exit 1

reset_stat()
{
    echo reset > /sys/kernel/debug/color_page_alloc/control
    echo "reset stat.."
}
check_mem()
{
    echo "> $1"
    cat /proc/buddyinfo | tail -n 15
    cat /sys/kernel/debug/color_page_alloc/control
}
reset_stat
check_mem "Before"
./bandwidth -m $msize -t 5&
sleep 1
check_mem "Middle"
sleep 5
check_mem "After"
