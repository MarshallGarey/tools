#!/bin/bash

slurm_install_dir="/home/marshall/slurm/17.11/voyager"
sacctmgr="$slurm_install_dir/bin/sacctmgr"

###############################################################################
# Rebuild
###############################################################################

# Change to the Slurm install directory. We need to be there for all of this.
cd $slurm_install_dir

# recompile
echo "Rebuilding..."
cleanbuild-nodev.sh 2&>> $slurm_install_dir/5865bisect-build.out
echo "Done"
# restore state files
echo "Restoring state files..."
rm -rf state5865
cp -r state5865old state5865
echo "Done"
# restore database
echo "Restoring database..."
mysql -u marshall slurm_17_11 < bug5865.dump
echo "Done"

#done

###############################################################################
# Restart daemons
###############################################################################

# restart daemons - note I'm not using my script restart_slurm.sh, since that
# doesn't sleep at all, but I need to sleep to wait for the database upgrade and
# slurmctld state upgrade and nodes to start and check in with slurmctld.
echo "Restarting daemons..."
cd sbin
stop_slurm.sh
./slurmdbd
sleep 5
# wait for upgrade to finish before starting slurmctld
# This works, unless sacctmgr breaks, which it did (segfault) when I was
# bisecting from 17.02 to 17.11. So, I'm sleeping instead. It's fast enough.
#while true; do
#	$sacctmgr show assoc > /dev/null
#	if [ $? == 0 ]
#	then
#		break
#	else
#		echo "waiting for slurmdbd upgrade..."
#		sleep 1
#	fi
#done

./slurmctld
sleep 1
start_slurmd.sh 1 10 v
# Wait to make sure nodes are up
sleep 4
cd ..

###############################################################################
# Run the test:
###############################################################################
./test5865.sh
exit $?

