#!/bin/bash

# ==============================================================================
# DISABLE HIGH AVAILABILITY (HA) SERVICES
# ==============================================================================
# Proxmox assumes it is in an enterprise cluster and constantly writes HA logs
# to the SSD. If you only have a single node, this disables those services
# to extend your SSD lifespan.
# ==============================================================================

if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: This script must be run as root."
  exit 1
fi

echo "========================================================"
echo "🚀 DISABLING CLUSTER HA SERVICES (SSD SAVER)"
echo "========================================================"

echo ">> Stopping High Availability services..."
systemctl stop pve-ha-lrm
systemctl stop pve-ha-crm

echo ">> Disabling and masking services to prevent them from starting..."
# Disabling stops them from booting up
systemctl disable pve-ha-lrm
systemctl disable pve-ha-crm

# Masking ensures that no other software can accidentally trigger them to wake up
systemctl mask pve-ha-lrm
systemctl mask pve-ha-crm

echo "========================================================"
echo "🎉 SUCCESS: HA Services are disabled!"
echo "   Your SSD will now experience significantly fewer random writes."
echo ""
echo "👉 IF YOU BUY A SECOND MINI-PC IN THE FUTURE:"
echo "   To reverse this and build a cluster, simply run:"
echo "   systemctl unmask pve-ha-lrm pve-ha-crm"
echo "   systemctl enable --now pve-ha-lrm pve-ha-crm"
echo "========================================================"
