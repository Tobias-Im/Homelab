#!/bin/bash

# ==============================================================================
# SENSORS AUTO-CONFIGURATION (ZERO-TOUCH)
# ==============================================================================
# Automatically scans the motherboard for thermal probes and loads the correct
# kernel modules so you can monitor CPU and system temperatures.
# ==============================================================================

# 1. ROOT PRIVILEGE CHECK
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: This script must be run as root."
  exit 1
fi

echo "========================================================"
echo "🚀 CONFIGURING HARDWARE SENSORS"
echo "========================================================"

# Step 1: Check if lm-sensors is installed
if ! command -v sensors-detect >/dev/null 2>&1; then
    echo ">> lm-sensors is missing. Installing it now..."
    DEBIAN_FRONTEND=noninteractive apt-get install -y lm-sensors
fi

# Step 2: Run the automated detection
echo ">> Running automated sensor detection..."
# The --auto flag tells the script to automatically answer 'YES' to all safe 
# scanning questions. This ensures the script requires absolutely no human intervention.
sensors-detect --auto > /dev/null 2>&1

# Step 3: Load the newly discovered modules into the kernel immediately
echo ">> Loading sensor modules into the kernel..."
systemctl restart kmod 2>/dev/null || /etc/init.d/kmod start 2>/dev/null

echo "========================================================"
echo "✅ SUCCESS: Hardware sensors configured!"
echo "👉 You can now type 'sensors' in your terminal to view temperatures."
echo "========================================================"
