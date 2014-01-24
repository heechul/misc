DBGFS=/sys/kernel/debug/palloc

echo xor 13 17 > $DBGFS/control
echo xor 14 18 > $DBGFS/control
echo xor 15 19 > $DBGFS/control
echo xor 16 20 > $DBGFS/control

echo 1 > $DBGFS/use_mc_xor
cat $DBGFS/control
