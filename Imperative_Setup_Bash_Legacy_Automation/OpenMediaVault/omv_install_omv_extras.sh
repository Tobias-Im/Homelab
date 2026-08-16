#!/bin/bash

# ==============================================================================
# INSTALL OMV-EXTRAS
# ==============================================================================
# OMV-Extras is the official plugin repository for OpenMediaVault.
# You absolutely need this to unlock Docker, Compose, and Portainer in the UI.
# ==============================================================================

# 1. ROOT PRIVILEGE CHECK
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: This script must be run as root."
  exit 1
fi

echo "========================================================"
echo "🚀 INSTALLING OMV-EXTRAS PLUGIN REPOSITORY"
echo "========================================================"

echo ">> Downloading and running the official omv-extras install script..."

# This is the official command recommended by OpenMediaVault
wget -O - https://github.com/OpenMediaVault-Plugin-Developers/packages/raw/master/install | bash

echo "========================================================"
echo "🎉 SUCCESS: OMV-Extras is installed!"
echo "   You can now go to the OpenMediaVault Web GUI,"
echo "   navigate to Plugins, and install 'openmediavault-compose'!"
echo "========================================================"
