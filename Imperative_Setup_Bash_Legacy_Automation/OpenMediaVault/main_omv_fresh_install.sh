#!/bin/bash

# ==============================================================================
# OPENMEDIAVAULT FRESH INSTALL MASTER SCRIPT (TIMED EDITION)
# ==============================================================================

# 1. ROOT CHECK
if [ "$EUID" -ne 0 ]; then
    echo "❌ Error: This script must be run as root."
    exit 1
fi

# ==============================================================================
START_TIME=$(date +%s)

# 2. LOGGING SETUP
LOG_FILE="omv_install_log.log"
if [ -f "$LOG_FILE" ]; then mv "$LOG_FILE" "$LOG_FILE.bak"; fi
exec > >(tee -i "$LOG_FILE") 2>&1

echo "========================================================"
echo "📝 LOGGING ENABLED: Output saved to $PWD/$LOG_FILE"
echo "🚀 STARTING OPENMEDIAVAULT FRESH INSTALL SEQUENCE"
echo "========================================================"

# 3. PERMISSIONS
echo ">> Making all helper scripts executable..."
chmod ug+x *.sh 2>/dev/null

# 4. EXECUTION SEQUENCE

# --- Step 1: Essentials & User Setup ---

# Creates the 'Saturday' user and adds them to the 'sudo' and 'docker' groups.
if [ -f "./debian_setup_user_Saturday.sh" ]; then
    echo "--------------------------------------------------------"
    echo "👉 Step 1a: Running debian_setup_user_Saturday.sh"
    ./debian_setup_user_Saturday.sh
fi

# --- Step 2: Proxmox Integration ---

# Installs the QEMU Guest Agent so Proxmox can safely reboot this VM and see its IP.
if [ -f "./omv_install_qemu_guest_agent.sh" ]; then
    echo "--------------------------------------------------------"
    echo "👉 Step 2a: Running omv_install_qemu_guest_agent.sh"
    ./omv_install_qemu_guest_agent.sh
fi

# Edits the GRUB bootloader to enable the Proxmox xterm.js Web Console.
if [ -f "./omv_enable_serial_console.sh" ]; then
    echo "--------------------------------------------------------"
    echo "👉 Step 2b: Running omv_enable_serial_console.sh"
    ./omv_enable_serial_console.sh
fi

# --- Step 3: Core Tuning ---

# Reduces RAM swap-to-disk tendency from 60 to 1 to save SSD wear.
if [ -f "./omv_set_swappiness.sh" ]; then
    echo "--------------------------------------------------------"
    echo "👉 Step 3: Running omv_set_swappiness.sh"
    ./omv_set_swappiness.sh
fi

# --- Step 3: Updates, Utilities & Timezone ---

# Safely updates all OpenMediaVault packages to their latest versions.
if [ -f "./omv_system_update.sh" ]; then
    echo "--------------------------------------------------------"
    echo "👉 Step 3a: Running omv_system_update.sh"
    ./omv_system_update.sh
fi

# Configures the server to use the Bucharest timezone.
if [ -f "./omv_set_timezone_bucharest.sh" ]; then
    echo "--------------------------------------------------------"
    echo "👉 Step 3b: Running omv_set_timezone_bucharest.sh"
    ./omv_set_timezone_bucharest.sh
fi

# Creates handy terminal shortcuts (like typing 'll').
if [ -f "./omv_setup_alias.sh" ]; then
    echo "--------------------------------------------------------"
    echo "👉 Step 3c: Running omv_setup_alias.sh"
    ./omv_setup_alias.sh
fi

# Installs safe curated utilities (htop, ncdu, smartmontools, etc).
if [ -f "./omv_install_core_packages.sh" ]; then
    echo "--------------------------------------------------------"
    echo "👉 Step 3d: Running omv_install_core_packages.sh"
    ./omv_install_core_packages.sh
fi

# --- Step 4: OpenMediaVault Plugins ---

# Installs the official OMV-Extras repository to unlock Docker and Compose.
if [ -f "./omv_install_omv_extras.sh" ]; then
    echo "--------------------------------------------------------"
    echo "👉 Step 4: Running omv_install_omv_extras.sh"
    ./omv_install_omv_extras.sh
fi

# ------------------------------------------------------------------------------
# FINISH & CALCULATE TIME
# ------------------------------------------------------------------------------
END_TIME=$(date +%s)
TOTAL_SECONDS=$((END_TIME - START_TIME))
MINUTES=$((TOTAL_SECONDS / 60))
SECONDS=$((TOTAL_SECONDS % 60))

echo "========================================================"
echo "🎉 OPENMEDIAVAULT INSTALL SEQUENCE COMPLETE"
echo "========================================================"
echo "⏱️  Total Execution Time: ${MINUTES}m ${SECONDS}s"
echo "📄 Log file saved to: $PWD/$LOG_FILE"
echo "👉 CRITICAL NEXT STEPS:"
echo "   1. Ensure QEMU Guest Agent is enabled in the Proxmox VM Hardware tab."
echo "   2. Ensure the Serial Port is added if you want xterm.js to work."
echo "   3. REBOOT THIS VM to apply the Serial Console and Guest Agent."
echo "========================================================"

# Automatic Reboot
echo ""
echo "⚠️  A system reboot is highly recommended to apply all changes."
echo "🔄 Rebooting automatically in 5 seconds... Press Ctrl+C to cancel."
sleep 5
reboot
