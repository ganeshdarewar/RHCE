#!/bin/bash

# iSCSI target information
ISCSI_TARGET_IP="192.168.229.129"
ISCSI_TARGET_PORT="3260"
ISCSI_TARGET_IQN="iqn.1994-05.com.redhat:26b1519e5e1c"

# Install the iscsi-initiator packages.
sudo dnf install iscsi-initiator-utils -y

# Start & enable the iscsid service.
sudo systemctl enable --now iscsid

# iSCSI initiator name
ISCSI_INITIATOR_NAME=$(cat /etc/iscsi/initiatorname.iscsi | grep -oE 'InitiatorName=[^"]+' | cut -d '=' -f2)

# Scan & Find the iSCSI Target IQN
iscsiadm -m discovery -t sendtargets -p "$ISCSI_TARGET_IP:$ISCSI_TARGET_PORT"

# Connect the iSCSI Target shared lun in the local machine.
iscsiadm -m node -T "$ISCSI_TARGET_IQN" "$ISCSI_TARGET_IP:$ISCSI_TARGET_PORT" -l
#scsiadm -m node --targetname "$ISCSI_TARGET_IQN" --portal "$ISCSI_TARGET_IP:$ISCSI_TARGET_PORT" --login

# Wait for the device to be ready
sleep 5

# Find the new LUN device
NEW_DEVICE=$(iscsiadm -m session -P3 | awk '/Attached scsi disk/ { print $4; exit }')

if [ -z "$NEW_DEVICE" ]; then
    echo "Failed to find the new LUN device."
    exit 1
fi

# Partition the device (if needed)
# Replace /dev/sdX with the actual device name (e.g., /dev/sdb)
# echo -e "n\np\n1\n\n\nw" | fdisk /dev/"$NEW_DEVICE"

# Create a filesystem (ext4 in this case)
mkfs.ext4 /dev/"$NEW_DEVICE"

# Create a mount point directory
MOUNT_POINT="/opt/iscsi_mount"
mkdir -p "$MOUNT_POINT"

# Mount the filesystem
mount /dev/"$NEW_DEVICE" "$MOUNT_POINT"
