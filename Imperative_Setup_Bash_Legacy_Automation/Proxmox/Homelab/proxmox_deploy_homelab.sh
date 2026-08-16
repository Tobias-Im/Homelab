#!/bin/bash
# =========================================================================
# proxmox_deploy_homelab.sh
# Automated Imperative Deployment of Homelab App Server (VM 102)
# =========================================================================

VMID=102
VMNAME="Homelab"
TEMPLATE_ID=9000
STORAGE="local"
MAC_ADDR="52:54:00:11:22:33"
IP_CONFIG="ip=192.168.X.X/24,gw=192.168.X.X"

echo "========================================================"
echo "🚀 DEPLOYING HOMELAB APP SERVER (VM $VMID)"
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
echo ">> Configuring Hardware (8 Cores, 16GB RAM, Q35, OVMF)..."
qm set $VMID --cores 8 --cpu cputype=host
qm set $VMID --memory 16384
qm set $VMID --machine q35 --bios ovmf
qm set $VMID --vga std
qm set $VMID --agent enabled=1

# Step 4: Network
echo ">> Configuring Network (Bridge: vmbr0, MAC: $MAC_ADDR)..."
qm set $VMID --net0 virtio=$MAC_ADDR,bridge=vmbr0,firewall=0

# Step 5: Disk (Expand to 100GB and enable SSD/Discard)
echo ">> Configuring Boot Disk (100GB, SSD Emulation, Discard/TRIM)..."
qm disk resize $VMID scsi0 100G
# Update existing disk options
qm set $VMID --scsi0 $STORAGE:$VMID/vm-$VMID-disk-0.qcow2,discard=on,ssd=1,iothread=1

# Step 6: GPU Passthrough
echo ">> Configuring AMD GPU PCI Passthrough..."
qm set $VMID --hostpci0 mapping=amdgpu,pcie=1,rombar=0

# Step 7: EFI & Serial
echo ">> Configuring EFI Disk and Serial Console..."
qm set $VMID --efidisk0 $STORAGE:0,format=qcow2,efitype=4m,pre-enrolled-keys=1
qm set $VMID --serial0 socket

# Step 8: Cloud-Init
echo ">> Configuring Cloud-Init Network ($IP_CONFIG)..."
qm set $VMID --ipconfig0 $IP_CONFIG
qm set $VMID --ciuser Saturday

# Step 9: Boot Order
echo ">> Setting Auto-Start (Priority 2, 60s Delay)..."
qm set $VMID --onboot 1
qm set $VMID --startup order=2,up=60

echo ">> Ready! You can now start the VM using: qm start $VMID"
echo "========================================================"
echo "✅ HOMELAB APP SERVER DEPLOYMENT SCRIPT COMPLETE!"
echo "========================================================"
