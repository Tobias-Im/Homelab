#!/bin/bash

# ==============================================================================
# REMNUX MALWARE ANALYSIS VM DEPLOYMENT SCRIPT
# ==============================================================================
# This script automates the deployment of the REMnux Virtual Appliance on Proxmox
# based on official documentation. 
# ==============================================================================

if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: This script must be run as root on the Proxmox host."
  exit 1
fi

VMID=200
VMNAME="REMnux-Malware-Lab"
RAM=8192
CORES=4
STORAGE="local"
TARGET_DISK_SIZE="120G"

echo "========================================================"
echo "🚀 DEPLOYING REMNUX VIRTUAL APPLIANCE (VM $VMID)"
echo "========================================================"

if qm status $VMID > /dev/null 2>&1; then
    echo "❌ Error: VM $VMID already exists. Destroy it first if you want to recreate it."
    exit 1
fi

IMAGE_URL="https://download.remnux.org/202601/remnux-noble-amd64-proxmox.qcow2"

IMAGE_FILE="remnux-proxmox.qcow2"

echo ">> Downloading REMnux QCOW2 Image..."
if [ ! -f "$IMAGE_FILE" ]; then
    wget -O "$IMAGE_FILE" "$IMAGE_URL"
else
    echo ">> Image already downloaded, skipping."
fi

echo ">> Verifying SHA256 Hash..."
EXPECTED_HASH="95adcfd293b29aee77c0c95b2d0a9a7f8f2f7829c49f20b3def16b5b28638e93"
ACTUAL_HASH=$(sha256sum "$IMAGE_FILE" | awk '{print $1}')

if [ "$EXPECTED_HASH" != "$ACTUAL_HASH" ]; then
    echo "❌ Error: SHA256 hash mismatch!"
    echo "Expected: $EXPECTED_HASH"
    echo "Actual:   $ACTUAL_HASH"
    echo "Please ensure you have a valid download link."
    rm -f "$IMAGE_FILE"
    exit 1
else
    echo "✅ Hash verified successfully!"
fi

echo ">> Creating VM $VMID..."
# We use standard SeaBIOS because most pre-built QCOW2 appliances are legacy booting unless specified otherwise.
# We also set the SPICE (qxl) display as recommended by the REMnux documentation.
qm create $VMID --name "$VMNAME" --memory $RAM --cores $CORES --net0 virtio,bridge=vmbr0 --scsihw virtio-scsi-pci --vga qxl

echo ">> Importing disk into $STORAGE (This may take a few minutes)..."
qm importdisk $VMID "$IMAGE_FILE" $STORAGE --format qcow2

echo ">> Attaching disk to VM..."
qm set $VMID --scsihw virtio-scsi-single --scsi0 $STORAGE:$VMID/vm-$VMID-disk-0.qcow2,discard=on,ssd=1,iothread=1

echo ">> Resizing disk to $TARGET_DISK_SIZE..."
qm resize $VMID scsi0 $TARGET_DISK_SIZE

echo ">> Setting Boot Order..."
qm set $VMID --boot order=scsi0

echo ">> Enabling QEMU Guest Agent (Pre-installed in REMnux QCOW2)..."
qm set $VMID --agent enabled=1

# echo ">> Cleaning up downloaded image..."
# rm -f "$IMAGE_FILE"

echo ">> Starting VM $VMID..."
qm start $VMID

echo ">> Waiting for QEMU Guest Agent to initialize (this may take 30-60 seconds)..."
until qm agent $VMID ping > /dev/null 2>&1; do
    sleep 2
done
echo ">> Guest Agent is responding!"

echo ">> Triggering automated REMnux installation..."
echo "⚠️  This will take 15-45 minutes. DO NOT CLOSE THIS TERMINAL!"

# Run the command and capture the JSON output to get the PID
EXEC_RES=$(qm guest exec $VMID -- su -l root -c "sleep 10 && remnux install --user=remnux ; reboot" 2>&1)
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
    qm snapshot $VMID "Fresh-Install" --description "Automated snapshot after remnux install"
    
    echo "========================================================"
    echo "✅ SUCCESS! REMnux VM $VMID is fully upgraded and snapshotted!"
    echo "You can now safely close this terminal."
    echo "========================================================"
else
    echo "❌ Error: Failed to trigger guest installation."
    echo "Raw output from guest exec:"
    echo "$EXEC_RES"
fi
