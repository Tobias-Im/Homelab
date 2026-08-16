#!/bin/bash

# ==============================================================================
# ENABLE SERIAL CONSOLE (FOR PROXMOX XTERM.JS)
# ==============================================================================
# Configures the GRUB bootloader to output to the serial port (ttyS0).
# This allows the use of the scrollable 'xterm.js' web console in Proxmox.
# ==============================================================================

# 1. ROOT PRIVILEGE CHECK
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: This script must be run as root."
  exit 1
fi

echo "========================================================"
echo "🚀 CONFIGURING VIRTUAL SERIAL CONSOLE"
echo "========================================================"

GRUB_FILE="/etc/default/grub"

# Step 1: Ensure the GRUB file exists
if [ ! -f "$GRUB_FILE" ]; then
    echo "❌ Error: $GRUB_FILE not found. Is this a standard Debian/OMV VM?"
    exit 1
fi

# Step 2: Check if it's already configured (Idempotent)
if grep -q "console=ttyS0,115200" "$GRUB_FILE"; then
    echo "   ✅ Serial console is already configured in GRUB!"
else
    echo ">> Modifying GRUB configuration..."
    # We use sed to carefully append the console parameters to the existing GRUB_CMDLINE_LINUX_DEFAULT line
    # It safely keeps existing parameters (like "quiet") and just tacks ours onto the end inside the quotes.
    sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 console=tty0 console=ttyS0,115200"/' "$GRUB_FILE"
    
    echo ">> Updating GRUB bootloader..."
    update-grub
fi

echo "========================================================"
echo "🎉 SUCCESS: The OS is now ready for xterm.js!"
echo ""
echo "⚠️  CRITICAL NEXT STEPS TO MAKE IT WORK:"
echo "1. Shut down this VM completely (type 'poweroff')."
echo "2. In the Proxmox UI, go to the VM's Hardware tab."
echo "3. Click Add -> Serial Port (Leave as 0) -> Add."
echo "4. Start the VM."
echo "5. Open the xterm.js console and press ENTER to wake it up."
echo "========================================================"
