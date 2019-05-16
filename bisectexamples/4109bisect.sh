#!/bin/bash
# stop daemons
sudo kill $(cat run/*)
rm run/*.pid
# recompile
cleanbuild.sh
# restore state files
echo "Restoring state files..."
rm -rf state
cp -r stateold state
echo "Done"
# restore database
echo "Restoring database..."
mysql -u marshall slurm_1808 < 1808db.dump
echo "Done"
# restart daemons
echo "Restarting daemons..."
./sbin/slurmdbd
# wait for upgrade to finish before starting slurmctld
sleep 5
./sbin/slurmctld -i
sleep 1
cd sbin
sudo ./4109_start_nodes.sh
cd ..
sleep 2
echo "Done"
# see if they're up
srun hostname
