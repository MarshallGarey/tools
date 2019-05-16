#!/bin/bash
slurm_install_dir="/home/marshall/slurm/18.08/voyager"
sbatch="$slurm_install_dir/bin/sbatch"
scontrol="$slurm_install_dir/bin/scontrol"
scancel="$slurm_install_dir/bin/scancel"

cd $slurm_install_dir

# Spawn 4 jobs
# Hold each one in a single scontrol command
# Make sure they're all held (python program)
j1=`$sbatch --parsable --begin=now+100 --wrap="whereami"`
j2=`$sbatch --parsable --begin=now+100 --wrap="whereami"`
j3=`$sbatch --parsable --begin=now+100 --wrap="whereami"`
j4=`$sbatch --parsable --begin=now+100 --wrap="whereami"`
sleep 1
$scontrol hold $j1,$j2,$j3,$j4

./test5902.py
rc=$?
$scancel -u marshall
exit $rc
