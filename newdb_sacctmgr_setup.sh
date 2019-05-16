#!/bin/bash
sacctmgr -i add cluster voyager
sacctmgr -i add account test
sacctmgr -i add user marshall account=test
echo "done: sacctmgr show assoc tree:"
sacctmgr show assoc tree
