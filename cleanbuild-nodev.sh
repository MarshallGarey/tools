#!/bin/bash
# MUST RUN INSIDE SLURM INSTALL DIRECTORY
# Assign to a temporary variable to suppress the output.
tmp=$(stat ../slurm)
st1=$?
tmp=$(stat ../voyager)
st2=$?
if [ "$st1" != "0" ] || [ "$st2" != "0" ]
then
	echo "Error: You must run this inside a Slurm install directory."
	exit 1
fi

mypath=$(pwd)
rm -rf lib
mkdir lib
cd build
../../slurm/configure --prefix=$mypath --enable-multiple-slurmd
#make -j uninstall > /dev/null
#make -j install > /dev/null
make.py --with-contribs --with-docs
printf "\nDone building\n\n"
