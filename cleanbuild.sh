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
# Change to the build directory so that the logs get written there.
rm -rf build
mkdir build
cd build
../../slurm/configure --prefix=$mypath --enable-developer --enable-multiple-slurmd --disable-optimizations --enable-memory-leak-debug
printf "\nBuilding...\n\n"
#make -j install > /dev/null
#make.pl
# Broderick's make.py is fastest
#make.py --with-contribs --with-docs
make.py
rc=$?
printf "\nDone, exit $rc\n\n"
exit $rc
