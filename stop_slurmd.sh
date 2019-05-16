#!/bin/bash

# This script must be run inside the sbin directory inside of
# a slurm directory (not the root sbin directory; that would
# be very bad).
if [ "$PWD" = "/sbin" ] || [ "$PWD" = "/usr/local/sbin" ] || [ ${PWD##*/} != "sbin" ]
then
	echo "ERROR: Must run in sbin directory in a slurm directory."
	EOF
	exit 2
fi

# If the directory is empty, quietly exit, that
# just means that no Slurm daemons are running.
if [ -n "$(find ../run -prune -empty)" ]
then
	EOF
	exit 0
fi

# Kill all running Slurm daemons.
for pid in `cat ../run/*slurmd-*.pid`; do sudo kill $pid; done

exit 0
