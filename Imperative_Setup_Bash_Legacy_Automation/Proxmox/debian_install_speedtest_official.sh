#!/bin/bash

# ==============================================================================
# OOKLA SPEEDTEST CLI INSTALLER (OFFICIAL)
# ==============================================================================
# Replaces the slow Python 'speedtest-cli' with the official C++ 'speedtest'.
# ==============================================================================

# 1. ROOT CHECK
if [ "$EUID" -ne 0 ]; then
    echo "❌ Error: This script must be run as root."
    exit 1
fi

echo "========================================================"
echo "🚀 INSTALLING OFFICIAL OOKLA SPEEDTEST CLI"
echo "========================================================"

# 2. REMOVE OLD PYTHON VERSION
# We remove 'speedtest-cli' to avoid conflict or confusion.
echo ">> Step 1: Removing unofficial Python version (if exists)..."
apt-get remove speedtest-cli -y

# 3. INSTALL PREREQUISITES
echo ">> Step 2: Installing curl..."
apt-get update
apt-get install curl -y

# 4. ADD OFFICIAL REPOSITORY
echo ">> Step 3: Adding Ookla Repository..."
# This script from packagecloud adds the GPG key and sources list automatically.
curl -s curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | os=debian dist=trixie bash

# 5. INSTALL OFFICIAL BINARY
echo ">> Step 4: Installing 'speedtest' package..."
apt-get install speedtest -y

# 6. VERIFICATION
if command -v speedtest &> /dev/null; then
    echo "========================================================"
    echo "✅ SUCCESS: Official Speedtest installed!"
    echo "========================================================"
    echo "Version detected:"
    speedtest --version
    echo ""
    echo "👉 Run 'speedtest' to start a test."
    echo "👉 Run 'speedtest --accept-license' to skip the prompt in scripts."
else
    echo "❌ Error: Installation failed."
    exit 1
fi