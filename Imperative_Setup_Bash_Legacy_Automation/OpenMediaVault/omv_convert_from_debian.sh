#!/bin/bash

# ==============================================================================
# INSTALL OPENMEDIAVAULT CORE
# ==============================================================================
# This script converts a standard Debian 13/12 machine into an OpenMediaVault NAS.
# ==============================================================================

# 1. ROOT PRIVILEGE CHECK
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: This script must be run as root."
  exit 1
fi

echo "========================================================"
echo "🚀 INSTALLING OPENMEDIAVAULT CORE"
echo "========================================================"

# This can take up to 10 minutes depending on internet speed.
echo ">> Downloading and running the official OpenMediaVault installer script..."
wget -O - https://github.com/OpenMediaVault-Plugin-Developers/installScript/raw/master/install | bash

echo "========================================================"
echo "🎉 SUCCESS: OpenMediaVault Core is installed!"
echo "========================================================"
