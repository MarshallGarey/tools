#!/bin/bash
cd "/home/marshall/slurm/17.11/slurm/testsuite/expect"
./test12.2
rc=$?
echo "exit with rc $rc"
exit $rc
