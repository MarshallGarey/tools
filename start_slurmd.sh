#!/bin/bash

pt=pwd
offset=$1
count=$2
node=$3
zero=0
shift
shift
shift

# Make sure we have sudo privileges.
sudo -v
rc=$?
if [ $rc != 0 ]
then
	echo "failed, need sudo privileges to run this script"
	exit 1
fi
echo "Starting slurmd's $node[$offset-$count]"

for i in `seq $offset $count`; do
  sudo ./slurmd -N $node$i $@
done
