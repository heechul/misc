# ./profile.sh solo profile-train-solo.txt train
# for i in 1 2; do 
#     ./profile.sh corun profile-train-corun.txt train
# done

# ./profile.sh solo profile-ref-stall-solo.txt ref
# ./profile.sh corun profile-ref-stall-corun.txt ref
# ./profile.sh corun profile-ref-stall-corun.txt ref 1024

# mode outputfile workload corunsize coruntype benchb
# ./profile.sh solo profile-bw_read.txt na na na latency_16M
# ./profile.sh solo profile-bw_read.txt na na na bw_read_16M

#./profile.sh corun profile-bw_read.txt na 16384 read latency_16M
#./profile.sh corun profile-bw_read.txt na 16384 read bw_read_16M

./profile.sh solo profile-bw_write.txt na na na bw_read_16M

# ./profile.sh corun profile-bw_read.txt na 1024 read latency_1M
# ./profile.sh corun profile-bw_read.txt na 1024 write latency_1M

# ./profile.sh corun profile-bw_read.txt na 16384 write latency_1M

# ./profile.sh solo profile-bw_write.txt na na na bw_write_1M
# ./profile.sh corun profile-bw_write.txt na 1024 read bw_write_1M
# ./profile.sh corun profile-bw_write.txt na 1024 write bw_write_1M
# ./profile.sh corun profile-bw_write.txt na 16384 read bw_write_1M
# ./profile.sh corun profile-bw_write.txt na 16384 write bw_write_1M
