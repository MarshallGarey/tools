#!/usr/bin/env python3
# This program builds a new workspace directory for Slurm

import argparse
import os
import subprocess

def make_directories(slurm_src, slurm_install):
    install_subdirs = ["build", "lib", "log", "run", "spool", "state"]
    # Create all directories. The directory tree that we make looks like this:
    # slurm/<slurm-workspace-name>/
    #   slurm_src/ (this is where the git repo resides)
    #   slurm_install/ (this is the install directory)
    #     build/ (this is the build directory)
    #     lib/ (for shared object files)
    #     log/ (for all <daemonname>logfile)
    #     run/ (for all <daemonname>pidfile)
    #     spool/ (slurmdspooldir)
    #     state/ (statesavelocation)
    # Additional directories will be automatically created by the build process.
    # TODO: Check failures (for example, if the directory already exists)
    subprocess.run(["mkdir", "-p", slurm_src, slurm_install])
    for d in install_subdirs:
        subprocess.run(["mkdir", slurm_install + "/" + d])

def main(args):
    #print(args)
    slurm_git_repo = "git@github.com:SchedMD/slurm.git"
    slurm_branch = args.slurm_branch
    slurm_base = "/home/marshall/slurm/" + args.name + "/"
    slurm_src = slurm_base + "slurm"
    slurm_install = slurm_base + "voyager"
    config_prog = ["{:s}/configure".format(slurm_src), "--prefix={:s}".format(slurm_install), "--enable-developer", "--enable-multiple-slurmd", "--disable-optimizations", "--enable-memory-leak-debug", "--with-pam_dir={:s}".format(slurm_install + "/lib")]
    build_prog = ["/home/marshall/tools/make.pl", "1"]
    build_dir = slurm_install + "/build"

    print("Setting up Slurm workspace for branch {:s} at {:s}\n".format(slurm_branch, slurm_base))

    make_directories(slurm_src, slurm_install)

    # Clone only the branch we want to make it faster. Clone it into slurm_src
    print("Cloning git branch {:s}".format(slurm_branch))
    subprocess.run(["git", "clone", "-b", slurm_branch, "--single-branch", slurm_git_repo, slurm_src])

    # Configure and build
    if args.build:
        print("Configuring, building, and installing")
        os.chdir(build_dir)
        subprocess.run(config_prog)
        subprocess.run(build_prog)

    # Copy slurm etc directory
    print("Copy these files from {:s}: ".format(args.conf_dir))
    subprocess.run(["ls", args.conf_dir])
    print("")
    subprocess.run(["cp", "-rL", args.conf_dir, slurm_install])

    # TODO: Change paths in slurm.conf and slurmdbd.conf
    # TODO: Change ports in slurm.conf and slurmdbd.conf
    # TODO: Set database name in slurmdbd.conf
    # TODO: Actually start slurm, initialize database (cluster and associations), start daemons
    return 0


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Create Slurm workspace.")
    parser.add_argument("slurm_branch", help="Name of Slurm branch")
    parser.add_argument("name", help="Name of workspace")
    parser.add_argument("-b", "--with-build", dest="build", action="store_true", default=False, help="Also configure and build and install Slurm")
    parser.add_argument("conf_dir", help="Directory to copy the config from")
    # Turn args into a dictionary
    args = parser.parse_args()
    main(args)
