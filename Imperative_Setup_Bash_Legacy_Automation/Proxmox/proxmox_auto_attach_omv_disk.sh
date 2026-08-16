#!/bin/bash

# ==============================================================================
# OMV AUTOMATIC DISK ATTACHMENT DAEMON
# ==============================================================================
# This script runs on a cron schedule to detect if OpenMediaVault (VM 101) 
# has been recreated by Terraform. If the VM exists, but the 8TB UGREEN 
# physical disk is NOT attached, it will automatically attach it.
# ==============================================================================

# Ensure cron can find Proxmox system binaries like 'qm'
export PATH=/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/sbin:/usr/local/bin

VM_ID="101"
DISK_ID="usb-ST8000NM_017B-2TJ103_26A1EE83167E-0:0"
DISK_PATH="/dev/disk/by-id/$DISK_ID"

# 1. Check if VM 101 exists
if ! qm status "$VM_ID" > /dev/null 2>&1; then
    # VM doesn't exist yet (Terraform hasn't built it). Exit silently.
    exit 0
fi

# 2. Check if the disk is already attached to scsi1
if qm config "$VM_ID" | grep -q "scsi1:.*$DISK_ID"; then
    # Disk is already safely attached. Exit silently to avoid spam.
    exit 0
fi

# 3. If we reached here, the VM exists but the disk is missing! Attach it.
echo "[$(date)] Auto-attaching $DISK_ID to VM $VM_ID (Backup=0)..." >> /var/log/omv_disk_auto_attach.log
qm set "$VM_ID" -scsi1 "$DISK_PATH,backup=0"

echo "[$(date)] Disk successfully attached." >> /var/log/omv_disk_auto_attach.log
