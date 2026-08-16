#!/bin/bash
# ==============================================================================
# CYBERLAB LAB DEPLOYMENT SCRIPT
# ==============================================================================
# This script sequentially deploys all three malware analysis and hacking VMs.
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
echo "🚀 STARTING FULL CYBERLAB LAB DEPLOYMENT"
echo "========================================================"

echo ""
echo "--------------------------------------------------------"
echo " [1/3] Deploying Kali Linux..."
echo "--------------------------------------------------------"
bash "$DIR/proxmox_deploy_kali.sh"

echo ""
echo "--------------------------------------------------------"
echo " [2/3] Deploying REMnux..."
echo "--------------------------------------------------------"
bash "$DIR/proxmox_deploy_remnux.sh"

echo ""
echo "--------------------------------------------------------"
echo " [3/3] Deploying FLARE-VM Template..."
echo " NOTE: This script will block until the installation"
echo "       finishes and the VM shuts down automatically."
echo "--------------------------------------------------------"
bash "$DIR/proxmox_create_flarevm_template.sh"

echo ""
echo "========================================================"
echo "✅ SUCCESS! ALL CYBERLAB VMs HAVE BEEN DEPLOYED!"
echo "========================================================"
