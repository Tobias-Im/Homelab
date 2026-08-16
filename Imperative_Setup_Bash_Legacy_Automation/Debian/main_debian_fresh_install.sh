#!/bin/bash

# ==============================================================================
# DEBIAN VM FRESH INSTALL MASTER SCRIPT (TIMED EDITION)
# ==============================================================================

# 1. ROOT CHECK
if [ "$EUID" -ne 0 ]; then
    echo "❌ Error: This script must be run as root."
    exit 1
fi

# ==============================================================================
# 🔧 AUTO-FIX DATE AND TIME (CRITICAL FOR SSL/UPDATES)
# ==============================================================================
echo "⏳ Checking system time..."
if ! command -v curl >/dev/null 2>&1; then
    apt-get update -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false -qq
    apt-get install -y curl -qq
fi
if command -v curl >/dev/null 2>&1; then
    date -s "$(curl -s --head http://google.com | grep ^Date: | sed 's/Date: //g')"
    echo "✅ Date synchronized: $(date)"
else
    echo "⚠️ Warning: Time sync failed. SSL errors may occur."
fi
# ==============================================================================

START_TIME=$(date +%s)

# 2. LOGGING SETUP
LOG_FILE="debian_install_log.log"
if [ -f "$LOG_FILE" ]; then mv "$LOG_FILE" "$LOG_FILE.bak"; fi
exec > >(tee -i "$LOG_FILE") 2>&1

echo "========================================================"
echo "📝 LOGGING ENABLED: Output saved to $PWD/$LOG_FILE"
echo "🚀 STARTING DEBIAN VM FRESH INSTALL SEQUENCE"
echo "========================================================"

# 3. PERMISSIONS
echo ">> Making all helper scripts executable..."
chmod ug+x *.sh 2>/dev/null

# 4. EXECUTION SEQUENCE

# --- Step 1: Essentials & User Setup ---

# Installs the 'sudo' package to allow non-root users to execute admin commands.
if [ -f "./debian_install_sudo.sh" ]; then
    echo "--------------------------------------------------------"
    echo "👉 Step 1a: Running debian_install_sudo.sh"
    ./debian_install_sudo.sh
fi

# Creates the 'Saturday' user and adds them to the 'sudo' and 'docker' groups.
if [ -f "./debian_setup_user_Saturday.sh" ]; then
    echo "--------------------------------------------------------"
    echo "👉 Step 1b: Running debian_setup_user_Saturday.sh"
    ./debian_setup_user_Saturday.sh
fi

# --- Step 2: Proxmox Integration ---

# Installs the QEMU Guest Agent so Proxmox can safely reboot this VM and see its IP.
if [ -f "./debian_install_qemu_guest_agent.sh" ]; then
    echo "--------------------------------------------------------"
    echo "👉 Step 2a: Running debian_install_qemu_guest_agent.sh"
    ./debian_install_qemu_guest_agent.sh
fi

# Edits the GRUB bootloader to enable the Proxmox xterm.js Web Console.
if [ -f "./debian_enable_serial_console.sh" ]; then
    echo "--------------------------------------------------------"
    echo "👉 Step 2b: Running debian_enable_serial_console.sh"
    ./debian_enable_serial_console.sh
fi

# --- Step 3: Core Packages & Tuning ---

# Installs critical sysadmin utilities like htop, curl, wget, and networking tools.
if [ -f "./debian_install_core_packages.sh" ]; then
    echo "--------------------------------------------------------"
    echo "👉 Step 3a: Running debian_install_core_packages.sh"
    ./debian_install_core_packages.sh
fi

# Reduces RAM swap-to-disk tendency from 60 to 1 to save virtual disk space.
if [ -f "./debian_set_swappiness.sh" ]; then
    echo "--------------------------------------------------------"
    echo "👉 Step 3b: Running debian_set_swappiness.sh"
    ./debian_set_swappiness.sh
fi

# --- Step 4: Docker Environment ---

# Installs Docker Engine and Docker Compose (V2 Plugin) for container hosting.
if [ -f "./debian_install_docker.sh" ]; then
    echo "--------------------------------------------------------"
    echo "👉 Step 4: Running debian_install_docker.sh"
    ./debian_install_docker.sh
fi

# --- Step 5: Security ---

# Installs a firewall robot that permanently bans hackers who guess passwords incorrectly.
if [ -f "./debian_install_fail2ban.sh" ]; then
    echo "--------------------------------------------------------"
    echo "👉 Step 5a: Running debian_install_fail2ban.sh"
    ./debian_install_fail2ban.sh
fi

# Configures Debian to automatically download and install security patches in the background.
if [ -f "./debian_unattended_upgrades.sh" ]; then
    echo "--------------------------------------------------------"
    echo "👉 Step 5b: Running debian_unattended_upgrades.sh"
    ./debian_unattended_upgrades.sh
fi

# Disables the dangerous 'root' SSH login, forcing you to log in as 'Saturday'.
if [ -f "./debian_harden_ssh.sh" ]; then
    echo "--------------------------------------------------------"
    echo "👉 Step 5c: Running debian_harden_ssh.sh"
    ./debian_harden_ssh.sh
fi

# --- Step 6: Utilities ---

# Installs the official Ookla Speedtest CLI tool for checking network bandwidth.
if [ -f "./debian_install_speedtest_official.sh" ]; then
    echo "--------------------------------------------------------"
    echo "👉 Step 6a: Running debian_install_speedtest_official.sh"
    ./debian_install_speedtest_official.sh
fi

# Creates handy terminal shortcuts (like typing 'll' or 'update') to save time.
if [ -f "./debian_setup_alias.sh" ]; then
    echo "--------------------------------------------------------"
    echo "👉 Step 6b: Running debian_setup_alias.sh"
    ./debian_setup_alias.sh
fi

# --- Step 7: Hardware Acceleration ---

# Installs AMD non-free firmware and VAAPI libraries so Jellyfin can use the passed-through GPU.
if [ -f "./debian_install_amd_gpu_drivers.sh" ]; then
    echo "--------------------------------------------------------"
    echo "👉 Step 7: Running debian_install_amd_gpu_drivers.sh"
    ./debian_install_amd_gpu_drivers.sh
fi

# ------------------------------------------------------------------------------
# FINISH & CALCULATE TIME
# ------------------------------------------------------------------------------
END_TIME=$(date +%s)
TOTAL_SECONDS=$((END_TIME - START_TIME))
MINUTES=$((TOTAL_SECONDS / 60))
SECONDS=$((TOTAL_SECONDS % 60))

echo "========================================================"
echo "🎉 DEBIAN VM FRESH INSTALL SEQUENCE COMPLETE"
echo "========================================================"
echo "⏱️  Total Execution Time: ${MINUTES}m ${SECONDS}s"
echo "📄 Log file saved to: $PWD/$LOG_FILE"
echo "👉 CRITICAL NEXT STEPS:"
echo "   1. Ensure QEMU Guest Agent is enabled in the Proxmox VM Hardware tab."
echo "   2. Ensure the AMD GPU is passed through as a PCI Device in the Hardware tab."
echo "   3. REBOOT THIS VM to apply the Serial Console, GPU drivers, and Guest Agent."
echo "========================================================"

# Automatic Reboot
echo ""
echo "⚠️  A system reboot is highly recommended to apply all changes."
echo "🔄 Rebooting automatically in 5 seconds... Press Ctrl+C to cancel."
sleep 5
reboot