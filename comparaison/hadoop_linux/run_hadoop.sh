#!/bin/bash -i

sudo -i
cd /home/ubuntu 

# Create the input folder if does not exist, since we are using hadoop in standalone mode, no need to start a hdfs namenode.
if [[ ! -d "input" ]]; then 
    mkdir input
else 
    rm -f input/*
fi

# Delete the output folder if exist
if [[ -d "output" ]]; then 
    rm -rf output
fi

# Copy the file in the input directoy 
mv pg4300.txt input/

source ~/.profile

# Run the hadoop command on the existing wordCout example and measure the exuction time using time command
# We use file descriptor to redirect commands outputs to our local machine or remote instance. 
# For instance, echo "pg4300.txt" 1>&2 will be redirected to the local machine since we are listening on stderr
echo "pg4300.txt" 1>&2 | { time -p hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.4.jar wordcount input output 2> hadoop.logs ; }
