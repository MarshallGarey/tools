#!/usr/bin/python3
import os
import time
import sys

def main(argv=None):
    srun = "/home/marshall/slurm/17.11/byu/bin/srun"
    jobname = "/bin/sleep"
    #jobname = "whereami"
    if len(argv) > 1:
        numjobs = int(argv[1])
    else:
        numjobs=20
    if len(argv) > 2:
        jobtime = int(argv[2])
    else:
        jobtime = 10
    print("run %d jobs for %d seconds" % (numjobs, jobtime))
    for i in range(0,numjobs):
        os.system("%s --exclusive -N1 --ntasks-per-node=1 \
                --cpu-bind=threads \
                --hint=nomultithread %s %d &" % (srun, jobname, jobtime))
    time.sleep(1)

if __name__ == "__main__":
    main(sys.argv)
