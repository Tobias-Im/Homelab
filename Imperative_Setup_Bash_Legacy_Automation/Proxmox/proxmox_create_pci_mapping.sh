#!/bin/bash
# Proxmox PCI Resource Mapping Automation
# This script creates a cluster-wide Datacenter Resource Mapping for the AMD GPU.
# This allows Terraform to safely passthrough the GPU using the 'amdgpu' mapping name.

# 1. ROOT CHECK
if [ "$EUID" -ne 0 ]; then
    echo "❌ Error: This script must be run as root (use sudo)."
    exit 1
fi

MAPPING_ID="amdgpu"
NODE="pve1"
PCI_PATH="0000:05:00.0"
PCI_SLOT="05:00.0"

# Proxmox requires the exact Vendor:Device ID (e.g., 1002:1638) for the mapping
# We extract it dynamically using lspci
HARDWARE_ID=$(lspci -n -s $PCI_SLOT | awk '{print $3}')

# Proxmox 8 also requires the IOMMU Group to prevent hardware topology mismatches
IOMMU_GROUP=$(basename $(readlink /sys/bus/pci/devices/0000:$PCI_SLOT/iommu_group))

# Proxmox 8 ALSO requires the Subsystem-ID (Sub-Vendor:Sub-Device)
SUB_VENDOR=$(cat /sys/bus/pci/devices/0000:$PCI_SLOT/subsystem_vendor | sed 's/0x//')
SUB_DEVICE=$(cat /sys/bus/pci/devices/0000:$PCI_SLOT/subsystem_device | sed 's/0x//')
SUBSYSTEM_ID="${SUB_VENDOR}:${SUB_DEVICE}"

echo "Creating Proxmox PCI Resource Mapping for $MAPPING_ID at $PCI_PATH (ID: $HARDWARE_ID, IOMMU: $IOMMU_GROUP, Subsystem: $SUBSYSTEM_ID) on node $NODE..."

# Delete the old mapping if it exists to overwrite it with the correct properties
pvesh delete /cluster/mapping/pci/$MAPPING_ID >/dev/null 2>&1

# Use pvesh to create the mapping programmatically
pvesh create /cluster/mapping/pci --id $MAPPING_ID --map node=$NODE,path=$PCI_PATH,id=$HARDWARE_ID,iommugroup=$IOMMU_GROUP,subsystem-id=$SUBSYSTEM_ID
if [ $? -eq 0 ]; then
    echo "✅ Mapping '$MAPPING_ID' created successfully!"
else
    echo "❌ Failed to create mapping."
fi
