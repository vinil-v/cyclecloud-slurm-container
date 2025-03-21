#!/bin/bash
set -e
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

PYXIS_VERSION=0.20.0
SHARED_DIR=/sched/pyxis

echo "Waiting for pyxis library to be available"
timeout 360s bash -c "until (ls $SHARED_DIR/spank_pyxis.so); do sleep 10; done"
echo "Pyxis library is available"
mkdir -p /usr/lib64/slurm
cp -fv $SHARED_DIR/spank_pyxis.so /usr/lib64/slurm
chmod +x /usr/lib64/slurm/spank_pyxis.so

ln -s /sched/plugstack.conf /etc/slurm/plugstack.conf
ln -s /sched/plugstack.conf.d /etc/slurm/plugstack.conf.d