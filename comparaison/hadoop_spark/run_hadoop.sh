#!/bin/bash -i

sudo -i

cd /home/ubuntu

# Create the input folder if does not exist
if [[ ! -d "input" ]]; then 
    mkdir input
else 
    rm -f input/*
fi

# Delete the output folder if exist
if [[ -d "output" ]]; then 
    rm -rf output
fi

#Download the dataset files under the directory dataset if it does not exist
if [[ ! -d "dataset" ]]; then 
    wget -P dataset http://www.gutenberg.ca/ebooks/buchanj-midwinter/buchanj-midwinter-00-t.txt > /dev/null 2>&1
    wget -P dataset http://www.gutenberg.ca/ebooks/carman-farhorizons/carman-farhorizons-00-t.txt > /dev/null 2>&1
    wget -P dataset http://www.gutenberg.ca/ebooks/colby-champlain/colby-champlain-00-t.txt > /dev/null 2>&1
    wget -P dataset http://www.gutenberg.ca/ebooks/cheyneyp-darkbahama/cheyneyp-darkbahama-00-t.txt > /dev/null 2>&1
    wget -P dataset http://www.gutenberg.ca/ebooks/delamare-bumps/delamare-bumps-00-t.txt > /dev/null 2>&1
    wget -P dataset http://www.gutenberg.ca/ebooks/charlesworth-scene/charlesworth-scene-00-t.txt > /dev/null 2>&1
    wget -P dataset http://www.gutenberg.ca/ebooks/delamare-lucy/delamare-lucy-00-t.txt > /dev/null 2>&1
    wget -P dataset http://www.gutenberg.ca/ebooks/delamare-myfanwy/delamare-myfanwy-00-t.txt > /dev/null 2>&1
    wget -P dataset http://www.gutenberg.ca/ebooks/delamare-penny/delamare-penny-00-t.txt > /dev/null 2>&1
fi

source ~/.profile

#For each file into dataset directory
for file in dataset/*; do
    #Get the file name
    file_name=$(basename "$file")
    echo "Starting Wordcount on $file_name"
    #Copy the file in input directory
    cp $file input/
    #Run the hadoop command 3 times for each file
    for i in {1..3}; do
        echo $file_name 1>&2 | { time -p hadoop jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.4.jar wordcount input output 2>hadoop.logs; }
        #Remove the output directory for the next iteration
        rm -rf output
    done
    #Remove the input directory for the next file
    rm -f input/*    
done   
