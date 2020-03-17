#!/bin/bash


#Create the table
myTable=table.$1
rm $myTable
for ii in $(ls log*$1*); do
   tail -20 $ii | grep ClockTime >> $myTable
done
cat $myTable

#Extracting the average
N=$(wc -l $myTable | awk '{print $1}')
awk '{ total += $7; count++ } END { print total/count }' $myTable
