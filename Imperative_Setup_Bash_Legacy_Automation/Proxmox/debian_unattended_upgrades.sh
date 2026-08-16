#!/bin/bash

# ==============================================================================
# UNATTENDED UPGRADES (SAFE PROXMOX APPROACH)
# ==============================================================================
# Automates the installation of critical Debian security patches.
# Specifically blacklists Proxmox packages to prevent accidental hypervisor 
# updates from breaking Virtual Machines.
# ==============================================================================

# 1. ROOT PRIVILEGE CHECK
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: This script must be run as root."
  exit 1
fi

echo "========================================================"
echo "🚀 CONFIGURING UNATTENDED UPGRADES"
echo "========================================================"

# Step 1: Install required packages
echo ">> Installing unattended-upgrades..."
DEBIAN_FRONTEND=noninteractive apt-get install -y unattended-upgrades apt-listchanges

# Step 2: Enable the automatic upgrade timer
echo ">> Enabling daily auto-upgrade schedule..."
cat <<EOF > /etc/apt/apt.conf.d/20auto-upgrades
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF

# Step 3: Configure the strict safety policy
echo ">> Writing strict Proxmox safety policy..."
cp /etc/apt/apt.conf.d/50unattended-upgrades /etc/apt/apt.conf.d/50unattended-upgrades.bak

# Create a fresh, highly controlled configuration
cat <<EOF > /etc/apt/apt.conf.d/50unattended-upgrades
// Automatically upgrade ONLY Debian Security packages
Unattended-Upgrade::Origins-Pattern {
    "origin=Debian,codename=\${distro_codename}-security,label=Debian-Security";
};

// DO NOT upgrade Proxmox-specific packages automatically
Unattended-Upgrade::Package-Blacklist {
    "pve-*";
    "qemu-*";
    "proxmox-*";
    "ceph-*";
    "zfs-*";
};

// Automatically run apt-get autoremove to clean up old kernels
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-New-Unused-Dependencies "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";

// NEVER automatically reboot a Proxmox node (protects running VMs)
Unattended-Upgrade::Automatic-Reboot "false";
EOF

# Step 4: Restart the service to apply changes
echo ">> Restarting unattended-upgrades service..."
systemctl restart unattended-upgrades

echo "========================================================"
echo "✅ SUCCESS: Safe Unattended Upgrades are now active!"
echo "   Your host will silently patch Debian vulnerabilities."
echo "   You must still manually click 'Upgrade' for Proxmox UI updates."
echo "========================================================"

# Step 5: Verification (Dry-Run to show the user it works)
echo ""
echo ">> Running a Dry-Run (Simulation) to verify configuration..."
unattended-upgrades --dry-run --debug

echo ""
echo ">> You can check past automated upgrades at any time by viewing:"
echo "   cat /var/log/apt/history.log"
