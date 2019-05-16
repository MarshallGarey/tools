#!/bin/bash
slurm_install_dir="/home/marshall/slurm/17.02/byu"
sacctmgr="$slurm_install_dir/bin/sacctmgr"

###
# Rebuild
###

# Change to the Slurm install directory. We need to be there for all of this.
cd $slurm_install_dir

# recompile
echo "Rebuilding..."
cleanbuild-nodev.sh 2&>> $slurm_install_dir/5902bisect-build.out
echo "Done"
# restore state files
echo "Restoring state files..."
rm -rf state5902
cp -r state5902old state5902
echo "Done"
# restore database
echo "Restoring database..."
mysql -u marshall slurm_1702 < bug5902.dump
echo "Done"

#done

###
# Restart daemons
###

# restart daemons
echo "Restarting daemons..."
cd sbin
stop_slurm.sh
./slurmdbd
sleep 5
# wait for upgrade to finish before starting slurmctld
# This works, unless sacctmgr breaks...
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

###
# Run the test:
###
./test5902.sh
exit $?
