#!/bin/bash
set -e
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

PYXIS_VERSION=0.20.0
SHARED_DIR=/sched/pyxis

# building pyxis library
# Copy pyxis library to cluster shared directory
cd /tmp
wget -q https://github.com/NVIDIA/pyxis/archive/refs/tags/v$PYXIS_VERSION.tar.gz
tar -xzf v$PYXIS_VERSION.tar.gz
cd pyxis-$PYXIS_VERSION
make

   # Copy pyxis library to cluster shared directory
logger -s "Copying Pyxis library to $SHARED_DIR"
mkdir -p ${SHARED_DIR}
cp -fv spank_pyxis.so ${SHARED_DIR}
chmod +x ${SHARED_DIR}/spank_pyxis.so

mkdir -p /sched/plugstack.conf.d
echo 'include /sched/plugstack.conf.d/*' > /sched/plugstack.conf
chown -R slurm:slurm /sched/plugstack.conf
echo 'required /usr/lib64/slurm/spank_pyxis.so runtime_path=/mnt/enroot/enroot-runtime' > /sched/plugstack.conf.d/pyxis.conf
chown slurm:slurm /sched/plugstack.conf.d/pyxis.conf

echo "Waiting for pyxis library to be available"
timeout 360s bash -c "until (ls $SHARED_DIR/spank_pyxis.so); do sleep 10; done"
echo "Pyxis library is available"
mkdir -p /usr/lib64/slurm
cp -fv $SHARED_DIR/spank_pyxis.so /usr/lib64/slurm
chmod +x /usr/lib64/slurm/spank_pyxis.so

ln -s /sched/plugstack.conf /etc/slurm/plugstack.conf
ln -s /sched/plugstack.conf.d /etc/slurm/plugstack.conf.d