#!/bin/bash -i

sudo -i
cd /home/ubuntu 

# Create the input folder if does not exist
if [[ ! -d "input" ]]; then 
    mkdir input
fi

# Delete the output folder if exist
if [[ -d "output" ]]; then 
    rm -rf output
fi

cp pg4300.txt input/

source ~/.profile

time hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.4.jar wordcount input output 2> hadoop.logs