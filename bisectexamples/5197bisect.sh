#!/bin/bash
# stop daemons
kill `cat run/slurmctld.pid`
kill `cat run/slurmdbd.pid`
# recompile
./cleanbuild.sh
# restore state files
echo "Restoring state files..."
rm -rf bug5197state
cp -r bug5197stateold bug5197state
echo "Done"
# restore database
echo "Restoring database..."
mysql -u marshall slurm_1711_bug5197 < bug5197db.dump
echo "Done"
# restart daemons
echo "Restarting daemons..."
./sbin/slurmdbd
# wait for upgrade to finish before starting slurmctld
sleep 5
./sbin/slurmctld
sleep 1
echo "Done"
# make sure they're up
./bin/sacctmgr show runaway byu
