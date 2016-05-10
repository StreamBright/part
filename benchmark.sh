#!/bin/bash

set -eux

cd "$(dirname "$0")"

paper_dir=~/repos/indexedrdd-paper/osdi16
figure_dir=$paper_dir/figures

CXX_OPTS='-Wall -Wextra -Wno-invalid-offsetof -O3 -std=c++11 -stdlib=libc++ -g'

####### Data structure performance comparison
data_file=$figure_dir/micro-out.txt
echo 'data=[' > $data_file

for value_size in '' '-DBIG_VAL'; do
    for b in 1 10 100 1000 10000 100000 1000000 10000000; do
        clang++ -DART -DBATCH_SIZE=$b $value_size -DKEY_LEN=4 -DRANDOM $CXX_OPTS -o ArtMicrobenchmark ArtMicrobenchmark.cpp
        ./ArtMicrobenchmark | tee -a $data_file

        clang++ -DHT -DBATCH_SIZE=$b $value_size -DKEY_LEN=4 -DRANDOM $CXX_OPTS -o ArtMicrobenchmark ArtMicrobenchmark.cpp
        ./ArtMicrobenchmark | tee -a $data_file

        clang++ -DRB -DBATCH_SIZE=$b $value_size -DKEY_LEN=4 -DRANDOM $CXX_OPTS -o ArtMicrobenchmark ArtMicrobenchmark.cpp
        ./ArtMicrobenchmark | tee -a $data_file

        clang++ -DBTREE -DBATCH_SIZE=$b $value_size -DKEY_LEN=4 -DRANDOM $CXX_OPTS -o ArtMicrobenchmark ArtMicrobenchmark.cpp
        ./ArtMicrobenchmark | tee -a $data_file
    done

    clang++ -DVECTOR $value_size -DKEY_LEN=4 -DRANDOM $CXX_OPTS -o ArtMicrobenchmark ArtMicrobenchmark.cpp
    ./ArtMicrobenchmark | tee -a $data_file
done


echo ']' >> $data_file


###### Stacked benchmark
data_file=$figure_dir/stacked.txt
echo 'stacked_data=[' > $data_file
echo '# 1. No batching, no node compaction'
clang++ -DART -DBATCH_SIZE=1 -DKEY_LEN=4 -DRANDOM $CXX_OPTS -o ArtMicrobenchmark ArtMicrobenchmark.cpp
./ArtMicrobenchmark | tee -a $data_file

# 2. +Key space transformations (improves all)

echo '# 3. +Batching, batch size=10,000 (improves insert performance)'
clang++ -DART -DBATCH_SIZE=10000 -DKEY_LEN=4 -DRANDOM $CXX_OPTS -o ArtMicrobenchmark ArtMicrobenchmark.cpp
./ArtMicrobenchmark | tee -a $data_file

echo '# 4. +Node compaction (improves scan performance)'
clang++ -DART -DART_REORDER_LEAVES -DBATCH_SIZE=10000 -DKEY_LEN=4 -DRANDOM $CXX_OPTS -o ArtMicrobenchmark ArtMicrobenchmark.cpp
./ArtMicrobenchmark | tee -a $data_file

echo ']' >> $data_file