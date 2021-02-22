#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail
#set -x 

NVME_DEVICE_NAME=${NVME_DEVICE_NAME:-nvme}
LOGICAL_VOLUME_GROUP=${LOGICAL_VOLUME_GROUP:-es_data}
LOGICAL_VOLUME=${LOGICAL_VOLUME:-es_data}
LOGICAL_VOLUME_COUNT=2
SSD_NVME_DEVICE_LIST=($(ls /sys/block | grep $NVME_DEVICE_NAME | xargs -I. echo /dev/. || true))


if [ -d  "/dev/$LOGICAL_VOLUME_GROUP" ]
then
  echo 'Volumes already present in "/dev/$LOGICAL_VOLUME_GROUP"'
  echo -e "\n$(ls -Al /dev/$LOGICAL_VOLUME_GROUP | tail -n +2)\n"
  echo "I assume that provisioning already happend, doing nothing!"
  sleep infinity
fi

echo "creating physical volumes"
pvcreate ${SSD_NVME_DEVICE_LIST[@]}
#pvscan

echo "creating vg $LOGICAL_VOLUME_GROUP"
vgcreate $LOGICAL_VOLUME_GROUP ${SSD_NVME_DEVICE_LIST[@]}
#vgdisplay

let VG_PERCENT=100/$LOGICAL_VOLUME_COUNT

for i in $( seq 1 $LOGICAL_VOLUME_COUNT )
do
    echo "creating logical volumes $LOGICAL_VOLUME$i"
    lvcreate -l $VG_PERCENT%VG -n $LOGICAL_VOLUME$i $LOGICAL_VOLUME_GROUP
    echo "creating ext4 file system"
    mkfs.ext4 /dev/$LOGICAL_VOLUME_GROUP/$LOGICAL_VOLUME$i
done