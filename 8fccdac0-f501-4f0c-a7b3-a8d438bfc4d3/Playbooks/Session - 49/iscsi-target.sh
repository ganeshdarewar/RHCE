#!/bin/bash

# Install required packages
sudo dnf install targetcli iscsi-initiator-utils -y

# Start & enable the iscsid service.
sudo systemctl enable --now iscsid

# Enable and start the target service
sudo systemctl enable target --now

# Configure the iSCSI target
sudo targetcli backstores/fileio create disk01 /opt/iscsi_disk.img 5G

sudo targetcli iscsi/ create iqn.1994-05.com.redhat:26b1519e5e1c
sudo targetcli iscsi/iqn.1994-05.com.redhat:26b1519e5e1c/tpg1/luns/ create /backstores/fileio/disk01
sudo targetcli iscsi/iqn.1994-05.com.redhat:26b1519e5e1c/tpg1/acls/ create iqn.1994-05.com.redhat:216f9698b869

# Configure firewall rules
sudo firewall-cmd --add-service=iscsi-target --permanent
sudo firewall-cmd --add-port=3260/tcp --permanent
sudo firewall-cmd --reload

echo "iSCSI target server setup complete!"
