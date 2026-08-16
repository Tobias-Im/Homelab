#!/bin/bash

# ==============================================================================
# IOMMU AUTO-CONFIGURATOR (EDUCATIONAL VERSION)
# ==============================================================================
# This script ensures your AMD Ryzen 5825U is ready for GPU Passthrough.
# It acts as both a "Doctor" (Checker) and a "Surgeon" (Fixer).
# ==============================================================================

# --- 1. DEFINE VARIABLES ---
# We use ANSI escape codes to make the text colored (Green/Red/Yellow).
# \033[0;32m is the code for Green. \033[0m resets the color back to normal.
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# The path to the main bootloader configuration file in Debian/Proxmox.
GRUB_FILE="/etc/default/grub"

# A "flag" variable to track if we made changes. 
# We start as 'false' (no changes yet).
NEEDS_REBOOT=false

# --- 2. ROOT PRIVILEGE CHECK ---
# $EUID is the "Effective User ID". ID 0 is always the Root (Administrator).
# -ne means "Not Equal".
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ Error: Must be run as root.${NC}"
    # Exit code 1 means the script finished with an error.
    exit 1
fi

echo "========================================================"
echo "🚀 IOMMU SETUP & DIAGNOSTIC"
echo "========================================================"

# ==============================================================================
# STEP 1: CHECK & FIX CONFIGURATION (THE "SURGEON")
# ==============================================================================
echo -n "Checking Bootloader Configuration... "

# 'grep' searches for text inside a file.
# -q means "Quiet" (don't output text, just tell me yes/no via exit code).
# We are looking for "amd_iommu=on" inside /etc/default/grub.
if grep -q "amd_iommu=on" "$GRUB_FILE"; then
    # If grep found the text, we are already configured.
    echo -e "${GREEN}OK (Configured)${NC}"
else
    # If grep did NOT find the text, we need to fix it.
    echo -e "${RED}MISSING${NC}"
    echo "--------------------------------------------------------"
    echo -e "${YELLOW}🔧 Fixing Configuration...${NC}"
    
    # 1. CREATE BACKUP
    # 'cp' copies the file. 
    # $(date +%s) adds a timestamp (seconds since 1970) so filenames are unique.
    cp "$GRUB_FILE" "$GRUB_FILE.bak.$(date +%s)"
    echo "   ✅ Backup saved."

    # 2. MODIFY THE FILE
    # 'sed' is the Stream Editor. It finds and replaces text.
    # -i means "In-place" (edit the file directly, don't just print the result).
    # Logic: Find 'GRUB_CMDLINE_LINUX_DEFAULT="quiet"'
    #        Replace with 'GRUB_CMDLINE_LINUX_DEFAULT="quiet amd_iommu=on iommu=pt initcall_blacklist=sysfb_init"'
    sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet"/GRUB_CMDLINE_LINUX_DEFAULT="quiet amd_iommu=on iommu=pt initcall_blacklist=sysfb_init"/' "$GRUB_FILE"
    echo "   ✅ Flags added to $GRUB_FILE."

    # 3. UPDATE THE BOOTLOADER
    # 'update-grub' reads the file we just edited and generates the real boot config.
    # > /dev/null 2>&1 hides all the messy text output unless there is a critical error.
    echo "   🔄 Updating Grub..."
    update-grub > /dev/null 2>&1
    echo "   ✅ Bootloader updated."
    
    # Set our flag to true, so we remember to tell the user to reboot later.
    NEEDS_REBOOT=true
    echo "--------------------------------------------------------"
fi

# ==============================================================================
# STEP 2: CHECK IF ACTIVE (THE "DOCTOR")
# ==============================================================================
echo -n "Checking IOMMU Activation Status...  "

# We check two things here:
# 1. [ -d ... ] Checks if the folder '/sys/kernel/iommu_groups' exists.
# 2. [ "$(ls -A ...)" ] Checks if that folder is NOT empty.
# If Linux has successfully isolated hardware, this folder will contain groups (1, 2, 3...).
if [ -d "/sys/kernel/iommu_groups" ] && [ "$(ls -A /sys/kernel/iommu_groups)" ]; then
    # If the folder exists and has stuff in it:
    echo -e "${GREEN}ACTIVE${NC}"
    echo ""
    echo -e "${GREEN}✅ SUCCESS: IOMMU is fully operational.${NC}"
    echo "   You can now proceed with GPU Passthrough."
else
    # If the folder is missing or empty:
    echo -e "${RED}INACTIVE${NC}"
    echo ""
    
    # Check the flag we set earlier. Did we just modify the file?
    if [ "$NEEDS_REBOOT" = true ]; then
        echo -e "${YELLOW}⚠️  CONFIGURATION APPLIED - REBOOT REQUIRED${NC}"
        echo "   The settings have been fixed, but Linux only reads them at startup."
        echo "   Please run 'reboot' now."
    else
        # If we didn't change files, but it's STILL off, the BIOS is the problem.
        echo -e "${RED}❌ ERROR: Config is correct, but IOMMU is still off.${NC}"
        echo "   This usually means 'IOMMU' or 'SVM Mode' is DISABLED in your BIOS."
        echo "   Action: Reboot, enter BIOS (Del/F7), and Enable Virtualization."
    fi
fi

echo "========================================================"