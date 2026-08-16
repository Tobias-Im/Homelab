#!/bin/bash

# ==============================================================================
# DEBIAN 13 CLOUD-INIT TEMPLATE GENERATOR
# ==============================================================================
# This script downloads the official Debian 13 (Trixie) Cloud image and converts 
# it into a Proxmox Cloud-Init Template (ID: 9000). 
# Terraform will use this template to instantly clone VMs!
# ==============================================================================

if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: This script must be run as root on the Proxmox host."
  exit 1
fi

TEMPLATE_ID=9000
TEMPLATE_NAME="debian-13-cloudinit"
STORAGE="local"
IMAGE_URL="https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2"
IMAGE_FILE="debian-13-genericcloud-amd64.qcow2"

echo "========================================================"
echo "🚀 CREATING DEBIAN 13 CLOUD-INIT TEMPLATE ($TEMPLATE_ID)"
echo "========================================================"

# Step 1: Check if template already exists
if qm status $TEMPLATE_ID > /dev/null 2>&1; then
    echo "❌ Error: VM/Template $TEMPLATE_ID already exists. Destroy it first if you want to recreate it."
    exit 1
fi

# Step 2: Download the official Debian Cloud Image
echo ">> Downloading Debian 13 Cloud Image..."
if [ ! -f "$IMAGE_FILE" ]; then
    wget -q --show-progress $IMAGE_URL
else
    echo ">> Image already downloaded, skipping."
fi

# Step 2.5: Inject QEMU Guest Agent into the image so Terraform doesn't hang
echo ">> Injecting QEMU Guest Agent into the image..."
virt-customize -a $IMAGE_FILE --install qemu-guest-agent --run-command "systemctl enable qemu-guest-agent"

# Step 3: Create the base VM
echo ">> Creating base Virtual Machine (ID: $TEMPLATE_ID)..."
qm create $TEMPLATE_ID --name $TEMPLATE_NAME --memory 4096 --cores 2 --cpu host --net0 virtio,bridge=vmbr0,firewall=1 --machine q35 --bios ovmf

# Step 4: Import the downloaded disk into Proxmox storage
echo ">> Importing disk into $STORAGE storage..."
qm importdisk $TEMPLATE_ID $IMAGE_FILE $STORAGE --format qcow2

# Step 5: Configure the VM to use the imported disk and Cloud-Init
echo ">> Attaching drives and configuring Cloud-Init parameters..."
qm set $TEMPLATE_ID --scsihw virtio-scsi-single --scsi0 $STORAGE:$TEMPLATE_ID/vm-$TEMPLATE_ID-disk-0.qcow2,discard=on,ssd=1,iothread=1
qm set $TEMPLATE_ID --efidisk0 $STORAGE:0,efitype=4m,pre-enrolled-keys=1,format=qcow2
qm set $TEMPLATE_ID --ide2 $STORAGE:cloudinit
qm set $TEMPLATE_ID --boot c --bootdisk scsi0
qm set $TEMPLATE_ID --serial0 socket --vga serial0
qm set $TEMPLATE_ID --agent enabled=1

# Resize the root disk to 32GB
echo ">> Resizing root disk to 32GB..."
qm resize $TEMPLATE_ID scsi0 32G

# Step 6: Convert the VM into a permanent Template
echo ">> Converting VM into a Template..."
qm template $TEMPLATE_ID

# Step 7: Cleanup
rm -f $IMAGE_FILE

echo "========================================================"
echo "🎉 SUCCESS: Cloud-Init Template $TEMPLATE_ID created!"
echo "   Terraform is now ready to instantly clone this template."
echo "========================================================"
