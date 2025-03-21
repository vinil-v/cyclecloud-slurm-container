#!/bin/bash
set -e
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
os_release=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
ENROOT_VERSION=3.5.0

arch=$(dpkg --print-architecture)
curl -fSsL -O https://github.com/NVIDIA/enroot/releases/download/v${ENROOT_VERSION}/enroot-check_${ENROOT_VERSION}_$(uname -m).run
chmod 755 enroot-check_*.run
./enroot-check_*.run --verify
curl -fSsL -O https://github.com/NVIDIA/enroot/releases/download/v${ENROOT_VERSION}/enroot_${ENROOT_VERSION}-1_${arch}.deb
curl -fSsL -O https://github.com/NVIDIA/enroot/releases/download/v${ENROOT_VERSION}/enroot+caps_${ENROOT_VERSION}-1_${arch}.deb
apt install -y ./*.deb

ENROOT_SCRATCH_DIR=/mnt/enroot
    if [ -d /mnt/nvme ]; then
        # If /mnt/nvme exists, use it as the default scratch dir
        mkdir -pv /mnt/nvme/enroot
        ln -s /mnt/nvme/enroot /mnt/enroot
    else
        mkdir -pv /mnt/scratch/enroot
        ln -s /mnt/scratch/enroot /mnt/enroot
    fi

    mkdir -pv /run/enroot $ENROOT_SCRATCH_DIR/{enroot-cache,enroot-data,enroot-temp,enroot-runtime}
    chmod -v 777 /run/enroot $ENROOT_SCRATCH_DIR/{enroot-cache,enroot-data,enroot-temp,enroot-runtime}

    # Configure enroot
    cat <<EOF > /etc/enroot/enroot.conf
ENROOT_RUNTIME_PATH /run/enroot/user-\$(id -u)
ENROOT_CACHE_PATH $ENROOT_SCRATCH_DIR/enroot-cache/group-\$(id -g)
ENROOT_DATA_PATH $ENROOT_SCRATCH_DIR/enroot-data/user-\$(id -u)
ENROOT_TEMP_PATH $ENROOT_SCRATCH_DIR/enroot-temp
ENROOT_SQUASH_OPTIONS -noI -noD -noF -noX -no-duplicates
ENROOT_MOUNT_HOME y
ENROOT_RESTRICT_DEV y
ENROOT_ROOTFS_WRITABLE y
MELLANOX_VISIBLE_DEVICES all
EOF

cp -fv /usr/share/enroot/hooks.d/50-slurm-pmi.sh /usr/share/enroot/hooks.d/50-slurm-pytorch.sh /etc/enroot/hooks.d