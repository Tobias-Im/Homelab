#!/bin/bash
# =========================================================================
# proxmox_deploy_omv.sh
# Automated Imperative Deployment of OpenMediaVault VM (ID 101)
# =========================================================================

VMID=101
VMNAME="OpenMediaVault"
TEMPLATE_ID=9000
STORAGE="local"
MAC_ADDR="52:54:00:77:88:99"
IP_CONFIG="ip=192.168.X.X/24,gw=192.168.X.X"

echo "========================================================"
echo "🚀 DEPLOYING OPENMEDIAVAULT (VM $VMID)"
echo "========================================================"

# Step 1: Check if VM exists
if qm status $VMID > /dev/null 2>&1; then
    echo "❌ Error: VM $VMID already exists. Destroy it first."
    exit 1
fi

# Step 2: Clone Template
echo ">> Cloning from Cloud-Init Template $TEMPLATE_ID..."
qm clone $TEMPLATE_ID $VMID --name $VMNAME --full true --storage $STORAGE

# Step 3: Hardware Specifications
echo ">> Configuring Hardware (4 Cores, 8GB RAM, Q35, OVMF)..."
qm set $VMID --cores 4 --cpu cputype=host
qm set $VMID --memory 8192
qm set $VMID --machine q35 --bios ovmf
qm set $VMID --vga std
qm set $VMID --agent enabled=1

# Step 4: Network
echo ">> Configuring Network (Bridge: vmbr0, MAC: $MAC_ADDR)..."
qm set $VMID --net0 virtio=$MAC_ADDR,bridge=vmbr0,firewall=0

# Step 5: Disk (Expand to 32GB and enable SSD/Discard)
echo ">> Configuring Boot Disk (32GB, SSD Emulation, Discard/TRIM)..."
qm disk resize $VMID scsi0 32G
# Update existing disk options
qm set $VMID --scsi0 $STORAGE:$VMID/vm-$VMID-disk-0.qcow2,discard=on,ssd=1,iothread=1

# Step 6: EFI & Serial
echo ">> Configuring EFI Disk and Serial Console..."
qm set $VMID --efidisk0 $STORAGE:0,format=qcow2,efitype=4m,pre-enrolled-keys=1
qm set $VMID --serial0 socket

# Step 7: Cloud-Init
echo ">> Configuring Cloud-Init Network ($IP_CONFIG)..."
qm set $VMID --ipconfig0 $IP_CONFIG
qm set $VMID --ciuser Saturday

# Step 8: Boot Order
echo ">> Setting Auto-Start (Priority 1)..."
qm set $VMID --onboot 1
qm set $VMID --startup order=1

echo ">> Ready! You can now start the VM using: qm start $VMID"
echo "========================================================"
echo "✅ OPENMEDIAVAULT DEPLOYMENT SCRIPT COMPLETE!"
echo "========================================================"
