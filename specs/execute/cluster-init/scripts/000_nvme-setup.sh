#!/bin/bash
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

    # If /mnt/nvme is already mounted then return
    grep -qs '/mnt/nvme ' /proc/mounts && return

    NVME_DISKS_NAME=`ls /dev/nvme*n1`
    NVME_DISKS=`ls -latr /dev/nvme*n1 | wc -l`

    # check if there are any NVMe disks and if so create a RAID0 array
    # and mount it to /mnt/nvme
    # if there are no NVMe disks then exit
    # if there are NVMe disks then create a RAID0 array and mount it to /mnt/nvme
    if [ "$NVME_DISKS" == "0" ]
    then
        exit 0
    else
        mkdir -p /mnt/nvme
        # Needed incase something did not unmount as expected. This will delete any data that may be left behind
        mdadm  --stop /dev/md*
        mdadm --create /dev/md12 -f --run --level 0 --name nvme --raid-devices $NVME_DISKS $NVME_DISKS_NAME
        mkfs.xfs -f /dev/md12
        mount /dev/md12 /mnt/nvme || exit 1
    fi

    chmod 1777 /mnt/nvme
    logger -s "/mnt/nvme mounted"