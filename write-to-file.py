#!/usr/bin/python3
import os
import time

with open("py_file_write.txt", "w") as f:
    f.write("hello world\n")
    # Write job id if in a Slurm job
    if "SLURM_JOB_ID" in os.environ:
        f.write("job id = %s\n" % (os.environ["SLURM_JOB_ID"]))
#time.sleep(9999)
exit(0)

