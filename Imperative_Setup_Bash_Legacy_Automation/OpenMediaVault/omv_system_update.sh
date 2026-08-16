#!/bin/bash

# ==============================================================================
# OMV SYSTEM UPDATE
# ==============================================================================
# Updates all core Debian packages and OpenMediaVault plugins.
# We use 'omv-upgrade' instead of 'apt upgrade' to ensure OMV database integrity.
# ==============================================================================

if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: This script must be run as root."
  exit 1
fi

echo "========================================================"
echo "🚀 UPDATING OPENMEDIAVAULT SYSTEM"
echo "========================================================"

echo ">> Running omv-upgrade..."
# omv-upgrade is the official, safe wrapper for apt update & upgrade on OMV
omv-upgrade

echo "========================================================"
echo "✅ SUCCESS: System is fully up to date!"
echo "========================================================"
