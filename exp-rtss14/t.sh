# ./profile.sh solo profile-train-solo.txt train
# for i in 1 2; do 
#     ./profile.sh corun profile-train-corun.txt train
# done

./profile.sh solo profile-ref-stall-solo.txt ref
./profile.sh corun profile-ref-stall-corun.txt ref
