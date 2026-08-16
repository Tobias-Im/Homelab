#!/bin/bash

# ==============================================================================
# PROXMOX FRESH INSTALL MASTER SCRIPT (TIMED EDITION)
# ==============================================================================

# 1. ROOT CHECK
if [ "$EUID" -ne 0 ]; then
    echo "❌ Error: This script must be run as root."
    exit 1
fi

# ==============================================================================
# 🔧 AUTO-FIX DATE AND TIME (CRITICAL FOR SNAPSHOTS)
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

# 2. LOGGING SETUP create login log file
LOG_FILE="install_log.log"
if [ -f "$LOG_FILE" ]; then mv "$LOG_FILE" "$LOG_FILE.bak"; fi
exec > >(tee -i "$LOG_FILE") 2>&1

echo "========================================================"
echo "📝 LOGGING ENABLED: Output saved to $PWD/$LOG_FILE"
echo "🚀 STARTING PROXMOX FRESH INSTALL SEQUENCE"
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

# Creates the 'Saturday' user and adds them to the 'sudo' and 'docker' groups for passwordless container management.
if [ -f "./debian_setup_user_Saturday.sh" ]; then
    echo "--------------------------------------------------------"
    echo "👉 Step 1b: Running debian_setup_user_Saturday.sh"
    ./debian_setup_user_Saturday.sh
fi

# Injects the hardcoded Terraform API token directly into the Proxmox database for zero-touch IaC restoration.
if [ -f "./proxmox_create_terraform_token.sh" ]; then
    echo "--------------------------------------------------------"
    echo "👉 Step 1c: Running proxmox_create_terraform_token.sh"
    ./proxmox_create_terraform_token.sh
fi

# --- Step 2: Repos ---

# Removes paid Enterprise repositories and enables free community No-Subscription repositories.
if [ -f "./proxmox_config_repos.sh" ]; then
    echo "--------------------------------------------------------"
    echo "👉 Step 2: Running proxmox_config_repos.sh"
    ./proxmox_config_repos.sh
fi

# --- Step 3: Storage ---

# Merges the annoying 'local-lvm' storage partition into the main 'local' partition for maximum SSD space.
if [ -f "./proxmox_remove_local_lvm.sh" ]; then
    echo "--------------------------------------------------------"
    echo "👉 Step 3a: Running proxmox_remove_local_lvm.sh"
    ./proxmox_remove_local_lvm.sh
fi

# Ensures Proxmox can store ISOs, Backups, and Containers on the newly merged storage.
if [ -f "./proxmox_enable_all_storage.sh" ]; then
    echo "--------------------------------------------------------"
    echo "👉 Step 3b: Running proxmox_enable_all_storage.sh"
    ./proxmox_enable_all_storage.sh
fi

# --- Step 4: Tuning & Optimization ---

# Reduces RAM swap-to-disk tendency from 60 to 1 to vastly improve SSD lifespan.
if [ -f "./debian_set_swappiness.sh" ]; then
    echo "--------------------------------------------------------"
    echo "👉 Step 4a: Running debian_set_swappiness.sh"
    ./debian_set_swappiness.sh
fi

# Turns off High Availability cluster logging to stop unnecessary SSD wear and tear on single-node servers.
if [ -f "./proxmox_disable_ha_services.sh" ]; then
    echo "--------------------------------------------------------"
    echo "👉 Step 4b: Running proxmox_disable_ha_services.sh (SSD Saver)"
    ./proxmox_disable_ha_services.sh
fi

# Forces the Ryzen CPU into 'performance' mode (or 'schedutil') for maximum Jellyfin transcoding speed.
if [ -f "./proxmox_set_cpu_governor.sh" ]; then
    echo "--------------------------------------------------------"
    echo "👉 Step 4c: Running proxmox_set_cpu_governor.sh"
    ./proxmox_set_cpu_governor.sh
fi

# --- Step 5: Core Packages ---

# Installs critical sysadmin utilities like htop, curl, wget, and networking tools.
if [ -f "./debian_install_core_packages.sh" ]; then
    echo "--------------------------------------------------------"
    echo "👉 Step 5: Running debian_install_core_packages.sh"
    ./debian_install_core_packages.sh
fi

# Installs Prometheus Node Exporter to integrate Proxmox into the Grafana monitoring dashboard.
if [ -f "./proxmox_install_node_exporter.sh" ]; then
    echo "--------------------------------------------------------"
    echo "👉 Step 5c: Running proxmox_install_node_exporter.sh"
    ./proxmox_install_node_exporter.sh
fi

# Installs libguestfs-tools to allow modifying Cloud-Init images with virt-customize.
if [ -f "./proxmox_install_libguestfs.sh" ]; then
    echo "--------------------------------------------------------"
    echo "👉 Step 5b: Running proxmox_install_libguestfs.sh"
    ./proxmox_install_libguestfs.sh
fi

# --- Step 7: Utilities ---

# Installs the official Ookla Speedtest CLI tool for checking network bandwidth.
if [ -f "./debian_install_speedtest_official.sh" ]; then
    echo "--------------------------------------------------------"
    echo "👉 Step 7a: Running debian_install_speedtest_official.sh"
    ./debian_install_speedtest_official.sh
fi

# Creates handy terminal shortcuts (like typing 'll' or 'update') to save time.
if [ -f "./debian_setup_alias.sh" ]; then
    echo "--------------------------------------------------------"
    echo "👉 Step 7b: Running debian_setup_alias.sh"
    ./debian_setup_alias.sh
fi

# --- Step 8: Security ---

# Installs a firewall robot that permanently bans hackers who guess your SSH password wrong 4 times.
if [ -f "./debian_install_fail2ban.sh" ]; then
    echo "--------------------------------------------------------"
    echo "👉 Step 8a: Running debian_install_fail2ban.sh"
    ./debian_install_fail2ban.sh
fi

# Configures Debian to automatically download and install security patches in the background.
if [ -f "./debian_unattended_upgrades.sh" ]; then
    echo "--------------------------------------------------------"
    echo "👉 Step 8b: Running debian_unattended_upgrades.sh"
    ./debian_unattended_upgrades.sh
fi

# Disables the dangerous 'root' SSH login, forcing you to log in as 'Saturday' instead.
if [ -f "./debian_harden_ssh.sh" ]; then
    echo "--------------------------------------------------------"
    echo "👉 Step 8c: Running debian_harden_ssh.sh"
    ./debian_harden_ssh.sh
fi

# --- Step 9: UI Tweaks ---

# Removes the annoying "You do not have a valid subscription" popup every time you log into the Proxmox UI.
if [ -f "./proxmox_remove_subscription_nag.sh" ]; then
    echo "--------------------------------------------------------"
    echo "👉 Step 9: Running proxmox_remove_subscription_nag.sh"
    ./proxmox_remove_subscription_nag.sh
fi

# --- Step 10: Hardware Specific & Passthrough ---

# Installs the latest proprietary security patches directly into the Ryzen CPU.
if [ -f "./debian_install_amd_microcode.sh" ]; then
    echo "--------------------------------------------------------"
    echo "👉 Running debian_install_amd_microcode.sh"
    ./debian_install_amd_microcode.sh
fi

# Installs lm-sensors so you can read the CPU temperatures from the command line.
if [ -f "./debian_configure_sensors.sh" ]; then
    echo "--------------------------------------------------------"
    echo "👉 Running debian_configure_sensors.sh"
    ./debian_configure_sensors.sh
fi

# Edits the GRUB bootloader to turn on AMD IOMMU, allowing hardware passthrough to VMs.
if [ -f "./proxmox_ryzen75825u_setup_iommu.sh" ]; then
    echo "--------------------------------------------------------"
    echo "👉 Running proxmox_ryzen75825u_setup_iommu.sh"
    ./proxmox_ryzen75825u_setup_iommu.sh
fi

# Loads the specific Linux kernel drivers needed to physically separate PCI devices.
if [ -f "./proxmox_setup_vfio_modules.sh" ]; then
    echo "--------------------------------------------------------"
    echo "👉 Running proxmox_setup_vfio_modules.sh"
    ./proxmox_setup_vfio_modules.sh
fi

# Locks the AMD Radeon Graphics card away from Proxmox so it can be handed perfectly to Jellyfin.
if [ -f "./proxmox_isolate_amd_gpu.sh" ]; then
    echo "--------------------------------------------------------"
    echo "👉 Running proxmox_isolate_amd_gpu.sh"
    ./proxmox_isolate_amd_gpu.sh
fi

# Creates the Datacenter PCI Resource Mapping for Terraform GPU Passthrough.
if [ -f "./proxmox_create_pci_mapping.sh" ]; then
    echo "--------------------------------------------------------"
    echo "👉 Running proxmox_create_pci_mapping.sh"
    ./proxmox_create_pci_mapping.sh
fi

# Fixes network dropouts by installing the proper Realtek 8168/8125 ethernet drivers.
if [ -f "./proxmox_ryzen75825u_install_realtek_driver.sh" ]; then
    echo "--------------------------------------------------------"
    echo "👉 Running proxmox_ryzen75825u_install_realtek_driver.sh"
    ./proxmox_ryzen75825u_install_realtek_driver.sh
fi

# --- Step 11: Automated VM Management ---

# Installs a cron daemon that continuously monitors for the OpenMediaVault VM and auto-attaches the physical disk.
if [ -f "./proxmox_install_omv_disk_watchdog.sh" ]; then
    echo "--------------------------------------------------------"
    echo "👉 Running proxmox_install_omv_disk_watchdog.sh"
    ./proxmox_install_omv_disk_watchdog.sh
fi

# Configures a udev rule to instantly auto-start the OMV VM the exact second the USB hard drive enclosure is powered on.
if [ -f "./proxmox_usb_autostart.sh" ]; then
    echo "--------------------------------------------------------"
    echo "👉 Running proxmox_usb_autostart.sh"
    ./proxmox_usb_autostart.sh
fi

# Installs Proxmox Backup Server natively on the bare-metal host and connects the external 2TB backup drive.
if [ -f "./proxmox_install_pbs.sh" ]; then
    echo "--------------------------------------------------------"
    echo "👉 Running proxmox_install_pbs.sh"
    ./proxmox_install_pbs.sh
fi

# --- Step 12: Build Core Template ---

# Downloads the Debian cloud image, injects guest agents, and creates the 32GB master template.
if [ -f "./proxmox_create_debian_cloudinit.sh" ]; then
    echo "--------------------------------------------------------"
    echo "👉 Running proxmox_create_debian_cloudinit.sh"
    ./proxmox_create_debian_cloudinit.sh
fi

# --- Step 13: Monitoring Agent ---

# Installs Telegraf to natively collect and send metrics to the InfluxDB monitoring server.
if [ -f "./proxmox_install_telegraf.sh" ]; then
    echo "--------------------------------------------------------"
    echo "👉 Running proxmox_install_telegraf.sh"
    ./proxmox_install_telegraf.sh
fi

# ------------------------------------------------------------------------------
# FINISH & CALCULATE TIME
# ------------------------------------------------------------------------------
END_TIME=$(date +%s)
TOTAL_SECONDS=$((END_TIME - START_TIME))
MINUTES=$((TOTAL_SECONDS / 60))
SECONDS=$((TOTAL_SECONDS % 60))

echo "========================================================"
echo "🎉 PROXMOX FRESH INSTALL SEQUENCE COMPLETE"
echo "========================================================"
echo "⏱️  Total Execution Time: ${MINUTES}m ${SECONDS}s"
echo "📄 Log file saved to: $PWD/$LOG_FILE"
echo "👉 NOTE: A system reboot is required for GPU/IOMMU changes to apply."

# Automatic Reboot
echo ""
echo "🔄 Rebooting automatically in 5 seconds... Press Ctrl+C to cancel."
sleep 5
reboot