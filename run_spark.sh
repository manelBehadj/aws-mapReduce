#!/bin/bash -i

sudo -i

cd /home/ubuntu

source ~/.profile

time run-example JavaWordCount /home/ubuntu/pg4300.txt 2> spark.logs