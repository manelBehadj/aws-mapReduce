#!/bin/bash -i

sudo -i

cd /home/ubuntu

# Export env variables
source ~/.profile

#For each file into dataset directory
for file in dataset/*; do
    #Get the file name
    file_name=$(basename "$file")
    echo "Starting Wordcount on $file_name"
    #Run the spark command 3 times for each file
    for i in {1..3}; do
        echo $file_name 1>&2 | { time -p run-example JavaWordCount "$file" 2>spark.logs ;}
    done
done 