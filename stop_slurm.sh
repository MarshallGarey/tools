#!/bin/bash

# This script must be run inside the sbin directory inside of
# a slurm directory (not the root sbin directory; that would
# be very bad).
if [ "$PWD" = "/sbin" ] || [ "$PWD" = "/usr/local/sbin" ] || [ ${PWD##*/} != "sbin" ]
then
	echo "ERROR: Must run in sbin directory in a slurm directory."
	exit 2
fi

# If the directory is empty, quietly exit, that
# just means that no Slurm daemons are running.
if [ -n "$(find ../run -prune -empty)" ]
then
	exit 0
fi

# Make sure we have sudo privileges.
sudo -v
rc=$?
if [ $rc != 0 ]
then
	echo "failed, need sudo privileges to run this script"
	exit 1
fi

# Kill all running Slurm daemons.
for pid in `cat ../run/*slurm*.pid`; do sudo kill $pid; done

exit 0
