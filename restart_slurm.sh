#!/bin/bash
# Stop and restart all Slurm daemons
# Must run in the sbin directory inside a Slurm install directory as SlurmUser.
# SlurmUser needs sudo privileges, since this will start the slurmd's as root.

# Make sure we have sudo privileges.
sudo -v
rc=$?
if [ $rc != 0 ]
then
	echo "failed, need sudo privileges to run this script"
	exit 1
fi

stop_slurm="/home/marshall/tools/stop_slurm.sh"
start_slurmd="/home/marshall/tools/start_slurmd.sh"

# This script must be run inside the sbin directory of
# a slurm install directory; also make sure we're not in
# the root or usr sbin directory.
if [ "$PWD" = "/sbin" ] || [ "$PWD" = "/usr/local/sbin" ] || [ ${PWD##*/} != "sbin" ]
then
	echo "ERROR: Must run in sbin directory in a slurm directory."
	exit 2
fi

# Become root
echo "Stop slurm daemons"
# Stop all slurm daemons
$stop_slurm
rc=$?
if [ $rc != 0 ]
then
	echo "error $rc, exiting"
	exit $rc
fi
sleep 1
$start_slurmd 1 13 v
sleep 1

echo "Starting slurmdbd"
./slurmdbd
# Wait for it to start up
sleep 2
echo "Starting slurmctld"
./slurmctld
sleep 1
echo "Done"
