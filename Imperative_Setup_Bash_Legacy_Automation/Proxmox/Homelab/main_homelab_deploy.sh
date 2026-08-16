#!/bin/bash
# ==============================================================================
# MAIN HOMELAB DEPLOYMENT SCRIPT
# ==============================================================================
# This script sequentially deploys the core Homelab VMs.
# ==============================================================================

set -e

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: Please run this script as root."
  exit 1
fi

# Get the directory where this script is located
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "========================================================"
echo "🚀 STARTING FULL HOMELAB IMPERATIVE DEPLOYMENT"
echo "========================================================"

echo ""
echo "--------------------------------------------------------"
echo " [1/3] Deploying OpenMediaVault (VM 101)..."
echo "--------------------------------------------------------"
bash "$DIR/proxmox_deploy_omv.sh"

echo ""
echo "--------------------------------------------------------"
echo " [2/3] Deploying Homelab App Server (VM 102)..."
echo "--------------------------------------------------------"
bash "$DIR/proxmox_deploy_homelab.sh"

echo ""
echo "--------------------------------------------------------"
echo " [3/3] Deploying Monitoring Server (VM 103)..."
echo "--------------------------------------------------------"
bash "$DIR/proxmox_deploy_monitoring.sh"

echo ""
echo "========================================================"
echo "✅ SUCCESS! ALL HOMELAB VMs HAVE BEEN FULLY DEPLOYED!"
echo "========================================================"
