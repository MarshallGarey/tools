#!/usr/bin/env python3

import sys
import asyncio
from pathlib import Path
import time
import argparse
from contextlib import contextmanager
from contextlib import ExitStack
import re
import os
import logging as log
import itertools as it


src = Path('src')
cwd = Path('.')
plugin_dirs = [src/'plugins'/x for x in [
    'job_submit',
    'task',
    'jobcomp']]
RECURSE = set([src, cwd/'contribs', src/'plugins', *plugin_dirs])
output = {}

def log_stream(level, stream):
    for line in stream.decode().splitlines():
        log.log(level, line)

async def run_subproc(prog, *args, shell=False, cwd=Path('.')):
    if shell:
        process = await asyncio.create_subprocess_shell(
                prog,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                cwd=str(cwd.resolve()))
    else:
        process = await asyncio.create_subprocess_exec(
                prog, *args,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                cwd=str(cwd.resolve()))

    stdout, stderr = await process.communicate()
    return stdout, stderr


async def make(path):
    global args
    # if path is in output dict, it is already done
    if path in output.keys():
        #print('already done: {}'.format(path))
        return

    # if dir is trivially recursable, recurse
    if path in RECURSE:
        children = [x for x in path.iterdir() if x.is_dir()]
        await asyncio.gather(*map(make, children))
    elif (path/'Makefile').exists():
        arg = ['-j']
        if args.install:
            arg.append('install')
        t0 = time.time()
        stdout, stderr = await run_subproc('make', *arg, cwd=path)
        t1 = time.time()

        output[path] = (stdout, stderr)
        log.info('done in {:0.2f}s: {}'.format(t1-t0, path))
        log_stream(log.WARN, stderr)


async def full_clean():
    pattern = re.compile("\$\s*(.*configure.*)")
    configlog = Path.cwd()/'config.log'
    if not configlog.exists():
        log.error('Cannot find config.log to extract configure command.')
        return False
    with open(Path.cwd()/'config.log', 'r') as f:
        text = f.read()
    match = re.search(pattern, text).groups()
    if match is None:
        log.error('configure command not found in config.log')
        return False
    else:
        match = match[0]
    print('found configure command:\n\t{}'.format(match))
    while True:
        print('continue? (Y/n) ')
        resp = input().lower()
        if resp in ('', 'y'):
            cmd = match
            break;
        elif resp == 'n':
            return False

    log.info('cleaning build directory')
    rm = 'rm -rf *'.format(Path.cwd())
    stdout, stderr = await run_subproc(rm, shell=True)
    log_stream(log.WARN, stderr)

    log.info('configuring build directory')
    stdout, stderr = await run_subproc(cmd, shell=True)
    output['full_clean'] = (stdout, stderr)
    log_stream(log.WARN, stderr)

    return True

async def clean():
    log.info('cleaning build directory')
    cmd = 'make -j clean'
    log.info('\t{}'.format(cmd))
    stdout, stderr = await run_subproc(cmd, shell=True)
    output['clean'] = (stdout, stderr)
    log_stream(log.WARN, stderr)


async def recheck():
    log.info('running configure recheck')
    cmd = './config.status --recheck'
    log.info('\t{}'.format(cmd))
    stdout, stderr = await run_subproc(cmd, shell=True)
    output['recheck'] = (stdout, stderr)
    log_stream(log.WARN, stderr)


async def reconfig():
    log.info('running reconfigure')
    cmd = './config.status'
    log.info('\t{}'.format(cmd))
    stdout, stderr = await run_subproc(cmd, shell=True)
    output['reconfig'] = (stdout, stderr)
    log_stream(log.WARN, stderr)


async def main(args):
    if args.full_clean:
        if await full_clean():
            log.info('full clean complete')
        else:
            log.error('full clean failed')
            return
    elif args.clean:
        await clean()

    if args.recheck:
        await recheck()
    if args.reconfig:
        await reconfig()

    # 'src/database' and 'src/bcast' are independent of 'src/common', 'src/api',
    # and 'src/db_api'
    first = asyncio.gather(*map(make, (src/'database', src/'bcast')))
    await make(src/'common')
    await make(src/'api')
    if (src/'db_api').exists():
        await make(src/'db_api')
    await first # but these need to be done before continuing

    # extra dirs are specified in --extra option
    extra = [make(cwd/x) for x in args.extra]
    if args.docs:
        extra.append(make(cwd/'doc'))
    if args.contribs:
        extra.append(make(cwd/'contribs'))
    extra = asyncio.gather(*extra)
    await make(src)
    await extra

    # optionally output all stdout/stderr to files
    if args.stdout or args.stderr:
        with ExitStack() as stack:
            outfile = None
            errfile = None
            if args.stdout:
                outfile = stack.enter_context(args.stdout.open('w'))
                log.info('writing all stdout to {}'.format(str(args.stdout)))
            if args.stderr:
                log.info('writing all stderr to {}'.format(str(args.stderr)))
                errfile = outfile if args.stderr == args.stdout else stack.enter_context(args.stderr.open('w'))
            for path, (stdout, stderr) in output.items():
                if outfile:
                    print('path: {}\nstdout:'.format(path), file=outfile)
                    for line in stdout.decode().splitlines():
                        print(line, file=outfile)
                    print('\n\n', file=outfile)
                if errfile:
                    print('path: {}\tstderr:'.format(path), file=errfile)
                    for line in stderr.decode().splitlines():
                        print(line, file=errfile)
                    print('\n\n', file=errfile)


@contextmanager
def cd(path):
    prev_dir = Path.cwd()
    os.chdir(path)
    try:
        yield
    finally:
        os.chdir(prev_dir)


parser = argparse.ArgumentParser(description='Fast make slurm. Does not make docs or contribs by default.')
parser.add_argument('build_dir', action='store', nargs='?', default='.',
        type=lambda s: Path(s), help='specify the build directory. Current working directory is used by default.')
parser.add_argument('--with-docs', dest='docs', action='store_true',
        default=False, help='also make docs')
parser.add_argument('--with-contribs', dest='contribs', action='store_true',
        default=False, help='also make contribs')
parser.add_argument('--with-all', dest='all', action='store_true',
        default=False, help='make docs and contribs')
parser.add_argument('--no-install', dest='install', action='store_false',
        default=True, help='build only, do not install')
parser.add_argument('--with-recheck', dest='recheck', action='store_true',
        default=False, help='run config.status --recheck before make')
parser.add_argument('--with-reconfig', dest='reconfig', action='store_true',
        default=False, help='run config.status before make')
parser.add_argument('--with-full-reconfig', dest='full_reconfig', action='store_true',
        default=False, help='run config.status and config.status --recheck before build')
parser.add_argument('--with-clean', dest='clean', action='store_true',
        default=False, help='run make clean before make')
parser.add_argument('--with-full-clean', dest='full_clean', action='store_true',
        default=False, help='remove build dir and reconfigure before make')
parser.add_argument('--stdout', dest='stdout', action='store',
        default=None, help='specify a file to write make stdout to')
parser.add_argument('--stderr', dest='stderr', action='store',
        default=None, help='specify a file to write make stderr to')
parser.add_argument('-v', '--verbose', dest='verbose', action='store_true',
        default=False, help='verbose output')
parser.add_argument('-q', '--quiet', dest='quiet', action='store_true',
        default=False, help='quiet output')
parser.add_argument('--extra', dest='extra', action='append',
        default=[], help='specify extra subdirs to build, such as contribs/pmi2. Use multiple times or pass comma-separated list')
args = parser.parse_args()

if args.all:
    args.docs, args.contribs = True, True
if args.full_reconfig:
    args.reconfig, args.recheck = True, True
if args.verbose:
    log.basicConfig(stream=sys.stdout, level=log.INFO, format='')
elif args.quiet:
    log.basicConfig(stream=sys.stdout, level=log.ERROR, format='')
else:
    log.basicConfig(stream=sys.stdout, level=log.WARN, format='')
if not (args.build_dir/'slurm/slurm.h').exists():
    log.error('This does not appear to be a Slurm build directory. Make sure to run configure first.')
    exit()
# flatten list of lists of specific dirs
args.extra = list(it.chain(*[s.split(',') for s in args.extra]))
if args.stdout:
    args.stdout = (cwd/args.stdout).resolve()
if args.stderr:
    args.stderr = (cwd/args.stderr).resolve()

#with ipdb.launch_ipdb_on_exception():
with cd(args.build_dir):
    loop = asyncio.get_event_loop()
    loop.run_until_complete(main(args))
    loop.close()
    #asyncio.run(main(args))

