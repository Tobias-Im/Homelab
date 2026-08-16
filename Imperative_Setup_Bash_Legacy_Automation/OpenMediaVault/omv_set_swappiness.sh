#!/bin/bash

# ==============================================================================
# SET SWAPPINESS (SSD LIFESPAN OPTIMIZATION)
# ==============================================================================
# Linux uses part of your hard drive as "virtual RAM" (swap) when real RAM runs low.
# The 'swappiness' value (0-100) dictates how aggressively it uses the hard drive.
# Debian defaults to 60. We reduce this to 1 to save the SSD from constant writes.
# ==============================================================================

# 1. ROOT PRIVILEGE CHECK
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: This script must be run as root."
  exit 1
fi

echo "========================================================"
echo "🚀 CONFIGURING SWAPPINESS (SSD SAVER)"
echo "========================================================"

CONF_FILE="/etc/sysctl.d/99-swappiness.conf"

# Step 1: Write the configuration file
echo ">> Setting swappiness to 1 in $CONF_FILE..."
echo "vm.swappiness=1" > "$CONF_FILE"

# Step 2: Apply the change immediately to the running system
echo ">> Applying changes to the live system..."
sysctl -p "$CONF_FILE"

echo "✅ Success! Swappiness reduced to 1."
