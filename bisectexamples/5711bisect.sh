#!/bin/bash
# stop daemons
sudo kill $(cat run/*)
rm run/*.pid
# recompile
./cleanbuild.sh
# restore state files
echo "Restoring state files..."
rm -rf state5711
cp -r state5711old state5711
echo "Done"
# restore database
echo "Restoring database..."
mysql -u marshall slurm_bug5711 < bug5711db.dump
echo "Done"
# restart daemons
echo "Restarting daemons..."
./sbin/slurmdbd
# wait for upgrade to finish before starting slurmctld
sleep 5
./sbin/slurmctld -i
sleep 1
cd sbin
sudo ./5711_start_nodes.sh
cd ..
sleep 2
echo "Done"
# see if they're up
sinfo
