#!/bin/bash

sudo -i

cd /home/ubuntu

# Create the input folder if does not exist, since we are using hadoop in standalone mode, no need to start a hdfs namenode.
if [[ ! -d "input" ]]; then 
    mkdir input
else 
    rm -f input/*
fi

# Delete the output directory if exist
if [[ -d "output" ]]; then 
    rm -rf output
fi

# Create classes directory if does not exist and delete it if exist
if [[ ! -d "classes" ]]; then 
    mkdir classes
else 
    rm -f classes/*
fi

# If the dataset file exists move it to input file
if [[ -f "data.txt" ]]; then 
    mv data.txt input
fi

source ~/.profile

# Compile the code 
/usr/lib/jvm/java-8-openjdk-amd64/bin/javac -classpath  $SPARK_DIST_CLASSPATH -d classes Recommendation.java

# Build the jar 
/usr/lib/jvm/java-8-openjdk-amd64/bin/jar -cvf recommendation.jar -C classes/ .

# Run the recommendation programm on hadoop
hadoop jar recommendation.jar poly.log8415.Recommendation input output