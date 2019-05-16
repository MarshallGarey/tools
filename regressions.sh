#!/bin/bash
exit 0

# Paths to tests
curr="/home/marshall/slurm/18.08"
master="/home/marshall/slurm/master"
#tools="/home/marshall/tools"

# Format for output file name
datecmd="date +%FT%H:%M:%S"

# Just for testing
include="1.1,1.2,1.3"

# Test 30.1 is expected to fail. The others will fail unless run by a user with
# a shell, so I need to make sure to run these manually.
exclude="30.1,6.14,10.3,10.7,10.9"

#
# Run the testsuite on the current version
#

cd "$curr/slurm/testsuite/expect"
outputfile="regression-results/`$datecmd`.out"
./regression.py -e$exclude >> $outputfile


#
# Run the testsuite on master
#

#cd "$master/slurm/testsuite/expect"
#outputfile="regression-results/`$datecmd`.out"
#./regression.py -e$exclude >> $outputfile








# Old stuff - testing different syntax so I could run the cronjob - and this
# script - as root, so I could restart the daemons before running. But I gave up
# on that.
#sbin="$master/voyager/sbin"
#cd $sbin
#sudo -H -u marshall bash -c "$sbin/slurmctld"
#sudo -H -u marshall bash -c "$sbin/slurmdbd"
#$tools/start_slurmd.sh 1 10 v
#sleep 5
#sudo -H -u marshall bash -c "./regression.py -e$exclude" >> $outputfile
#sudo -H -u marshall bash -c "./regression.py -i$include" >> $outputfile
