#!/bin/bash

# ==============================================================================
# KALI LINUX AUTOMATED VM DEPLOYMENT SCRIPT
# ==============================================================================
# This script automates the deployment of Kali Linux on Proxmox, including
# downloading the official QEMU image and installing kali-linux-everything.
# ==============================================================================

if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: This script must be run as root on the Proxmox host."
  exit 1
fi

VMID=202
VMNAME="Kali-Linux-Everything"
RAM=8192
CORES=4
STORAGE="local"
TARGET_DISK_SIZE="120G"

echo "========================================================"
echo "🚀 DEPLOYING KALI LINUX VIRTUAL APPLIANCE (VM $VMID)"
echo "========================================================"

if qm status $VMID > /dev/null 2>&1; then
    echo "❌ Error: VM $VMID already exists. Destroy it first if you want to recreate it."
    exit 1
fi

# Step 1: Install prerequisites
echo ">> Checking for p7zip-full..."
if ! command -v 7z &> /dev/null; then
    echo ">> p7zip-full not found. Installing..."
    apt-get update && apt-get install -y p7zip-full
fi

# Dynamically discover the latest Kali QEMU image filename
echo ">> Discovering latest Kali Linux QEMU image URL..."
LATEST_FILE=$(curl -sL https://cdimage.kali.org/current/ | grep -oP 'kali-linux-20[2-9][0-9]\.[0-9a-z]*-qemu-amd64\.7z' | head -n 1)

if [ -z "$LATEST_FILE" ]; then
    echo "❌ Error: Could not determine latest Kali version from cdimage.kali.org."
    exit 1
fi

IMAGE_URL="https://cdimage.kali.org/current/$LATEST_FILE"
ARCHIVE_FILE="$LATEST_FILE"

echo ">> Found latest version: $LATEST_FILE"
echo ">> Downloading Kali Linux QEMU Image (This is a 3GB+ download)..."
if [ ! -f "$ARCHIVE_FILE" ]; then
    wget -O "$ARCHIVE_FILE" "$IMAGE_URL"
else
    echo ">> Image archive already downloaded, skipping."
fi

echo ">> Extracting QCOW2 from 7z archive..."
# Extract and automatically overwrite if exists
7z x "$ARCHIVE_FILE" -y > /dev/null

# Find the extracted qcow2 file
IMAGE_FILE=$(find . -name "*.qcow2" | grep kali | head -n 1)

if [ -z "$IMAGE_FILE" ]; then
    echo "❌ Error: Could not find the extracted .qcow2 file!"
    exit 1
fi

echo ">> Creating VM $VMID..."
# Use kvm64 CPU and VirtIO standard drivers
qm create $VMID --name "$VMNAME" --memory $RAM --cores $CORES --net0 virtio,bridge=vmbr0 --scsihw virtio-scsi-pci --vga qxl

echo ">> Importing disk into $STORAGE (This may take a few minutes)..."
qm importdisk $VMID "$IMAGE_FILE" $STORAGE --format qcow2

echo ">> Attaching disk to VM..."
qm set $VMID --scsihw virtio-scsi-single --scsi0 $STORAGE:$VMID/vm-$VMID-disk-0.qcow2,discard=on,ssd=1,iothread=1

echo ">> Resizing disk to $TARGET_DISK_SIZE..."
qm resize $VMID scsi0 $TARGET_DISK_SIZE

echo ">> Setting Boot Order..."
qm set $VMID --boot order=scsi0

echo ">> Enabling QEMU Guest Agent (Pre-installed in Kali)..."
qm set $VMID --agent enabled=1

echo ">> Starting VM $VMID..."
qm start $VMID

echo ">> Waiting for QEMU Guest Agent to initialize (this may take 30-60 seconds)..."
until qm agent $VMID ping > /dev/null 2>&1; do
    sleep 2
done
echo ">> Guest Agent is responding!"

echo ">> Triggering automated kali-linux-everything installation..."
echo "⚠️  This will take SEVERAL HOURS (45GB+ of tools). DO NOT CLOSE THIS TERMINAL!"

# Run the command silently in the background via Guest Agent
# We use DEBIAN_FRONTEND=noninteractive to ensure it doesn't prompt for timezone/keyboard config
# We reboot at the end so our tracking loop catches the disconnect
EXEC_RES=$(qm guest exec $VMID -- su -l root -c "sleep 10 && apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y kali-linux-everything ; reboot" 2>&1)
PID=$(echo "$EXEC_RES" | grep -oP '"pid"\s*:\s*\K\d+')

if [[ -n "$PID" ]]; then
    echo ">> Installation started! Tracking process (PID: $PID)..."
    
    # Loop indefinitely until the process exits
    while true; do
        STATUS=$(qm guest exec-status $VMID $PID 2>&1)
        
        # Break if the process exited normally
        if echo "$STATUS" | grep -qP '"exited"\s*:\s*1'; then
            break
        fi

        # Break if the PID was garbage collected or threw an error
        if echo "$STATUS" | grep -qi 'error\|invalid'; then
            echo ">> Process tracking lost (PID expired). Assuming installation finished."
            break
        fi
        
        # If the Guest Agent goes offline, the reboot command fired successfully!
        if ! qm agent $VMID ping > /dev/null 2>&1; then
            echo ">> Guest agent disconnected! Installation finished, VM is rebooting..."
            break
        fi
        
        # Wait 60 seconds before checking again
        sleep 60
    done
    
    echo ">> Installation complete! Waiting for VM to fully reboot..."
    sleep 30
    
    # Wait for the guest agent to come back online after the reboot
    until qm agent $VMID ping > /dev/null 2>&1; do
        sleep 5
    done
    
    echo ">> VM is back online! Taking 'Fresh-Install' Snapshot..."
    qm snapshot $VMID "Fresh-Install" --description "Automated snapshot after kali-linux-everything install"
    
    echo "========================================================"
    echo "✅ SUCCESS! Kali Linux VM $VMID is fully upgraded and snapshotted!"
    echo "You can now safely close this terminal."
    echo "========================================================"
else
    echo "❌ Error: Failed to trigger guest installation."
    echo "Raw output from guest exec:"
    echo "$EXEC_RES"
fi
