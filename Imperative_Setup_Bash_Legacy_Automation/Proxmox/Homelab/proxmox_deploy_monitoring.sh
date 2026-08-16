#!/bin/bash

# ==============================================================================
# MONITORING VM DEPLOYMENT SCRIPT (1:1 with Terraform configuration)
# ==============================================================================
# Run this script directly on the Proxmox host shell to provision the Monitoring VM.
#
# It expects template VM 9000 (Debian 13 Cloud-Init) to already exist.

VMID=103
VM_NAME="Monitoring"
TEMPLATE_ID=9000
DATASTORE="local"

# Cloud-Init Variables
CI_USER="Saturday"
CI_PASSWORD="ChangeMe123!"
# Be sure to escape any special characters or just load from a file in production
CI_SSH_KEY="ssh-rsa <YOUR_SSH_PUBLIC_KEY>"

echo "==========================================================="
echo " Creating VM $VMID ($VM_NAME) from template $TEMPLATE_ID"
echo "==========================================================="

# 1. Clone the template (Full Clone)
echo "[1/6] Cloning template $TEMPLATE_ID..."
qm clone $TEMPLATE_ID $VMID --name "$VM_NAME" --full 1

# 2. Configure Core Hardware (CPU, Memory, Machine, BIOS, VGA, Qemu Agent)
echo "[2/6] Configuring hardware specs..."
qm set $VMID \
    --machine q35 \
    --bios ovmf \
    --cores 4 \
    --cpu host \
    --memory 12288 \
    --vga std \
    --agent 1

# 3. Configure Disk and Storage Settings
# Assuming template had scsi0 on $DATASTORE. We apply discard, ssd, and iothread.
echo "[3/6] Configuring disk settings..."
qm set $VMID --scsi0 $DATASTORE:$VMID/vm-$VMID-disk-1.qcow2,discard=on,iothread=1,ssd=1
# Resize disk to 100GB
qm disk resize $VMID scsi0 100G

# 4. Configure Network
echo "[4/6] Configuring network..."
qm set $VMID --net0 virtio=52:54:00:44:55:66,bridge=vmbr0,firewall=0

# 5. Configure Serial Console & Startup Policy
echo "[5/6] Configuring serial console and boot order..."
qm set $VMID --serial0 socket
qm set $VMID --onboot 1 --startup "order=3,up=30"

# 6. Configure Cloud-Init Initialization
echo "[6/6] Configuring Cloud-Init..."
qm set $VMID \
    --ipconfig0 ip=192.168.X.X/24,gw=192.168.X.X \
    --ciuser "$CI_USER" \
    --cipassword "$CI_PASSWORD" \
    --sshkeys "$(echo "$CI_SSH_KEY" | tr -d '\n')"

# Set the cloud-init datastore manually if needed
# qm set $VMID --citype nocloud --ide2 $DATASTORE:cloudinit

echo "==========================================================="
echo " VM $VMID ($VM_NAME) provisioning complete!"
echo " You can now start the VM with: qm start $VMID"
echo "==========================================================="
