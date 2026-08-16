#!/bin/bash

# ==============================================================================
# OMV SAFE UTILITY INSTALLER
# ==============================================================================
# This is a curated version of the Debian core packages script, specifically
# optimized to be 100% safe for OpenMediaVault.
# 
# REMOVED FOR SAFETY:
# - ufw (Would lock you out of OMV web interface)
# - fail2ban (OMV has its own official fail2ban plugin)
# - apache2-utils (OMV uses NGINX natively)
# - python3-full (OMV uses a strict python environment, pulling full could break it)
# ==============================================================================

# 1. ROOT PRIVILEGE CHECK
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: This script must be run as root."
  exit 1
fi

# ------------------------------------------------------------------------------
# 2. DEFINE SAFE PACKAGE LIST
# ------------------------------------------------------------------------------
PACKAGES=(
    # --- System Monitoring & Process Management ---
    htop            # Interactive process viewer
    cron            # Task scheduler
    btop            # Modern resource monitor (CPU/RAM/Disk)
    iotop           # Disk I/O usage per process
    sysstat         # System performance stats (sar, iostat)
    dstat           # Versatile resource statistics tool
    lsof            # List open files

    # --- Network Diagnostics (Safe) ---
    curl            # Data transfer (HTTP/S)
    iperf3          # Network throughput benchmark
    tcpdump         # Packet analyzer
    traceroute      # Route path tracing
    mtr             # Network diagnostic tool (ping + traceroute)
    whois           # IP/Domain registration info

    # --- Disk & Hardware Management (Crucial for a NAS) ---
    hdparm          # SATA/IDE device parameters
    fio             # Flexible I/O tester
    gdisk           # GPT partition tool
    parted          # Partition manipulation
    smartmontools   # S.M.A.R.T disk monitoring
    nvme-cli        # NVMe management
    lm-sensors      # Hardware sensors (temp/voltage)
    ncdu            # Disk usage analyzer (ncurses)

    # --- Editors & Terminal ---
    git             # Version control
    vim             # Advanced text editor
    neovim          # Hyper-extensible Vim-based editor
    tmux            # Terminal multiplexer
    bash-completion # Programmable completion for Bash
    xterm           # Terminal emulator

    # --- File Management & Archives ---
    rsync           # Fast file transfer/sync
    unzip           # Extract .zip files
    zip             # Create .zip files
    p7zip-full      # 7-Zip file archiver
    tree            # Directory structure viewer
    file            # File type guesser
    fzf             # Command-line fuzzy finder
    ripgrep         # Fast search tool (rg)
    fd-find         # User-friendly alternative to 'find'

    # --- Data Processing & Utilities ---
    jq              # Command-line JSON processor
    yq              # YAML processor
    watch           # Execute a program periodically
    hwinfo          # Lists details about your system
    lshw            # Lists details about your system
)

# ------------------------------------------------------------------------------
# 3. UPDATE REPOSITORIES & INSTALL PACKAGES
# ------------------------------------------------------------------------------
echo "Updating package lists..."
apt update

echo "Installing ${#PACKAGES[@]} safe packages for OpenMediaVault..."
DEBIAN_FRONTEND=noninteractive apt install -y "${PACKAGES[@]}"

# ------------------------------------------------------------------------------
# 4. VERIFICATION
# ------------------------------------------------------------------------------
if [ $? -eq 0 ]; then
    echo "✅ Success! All safe packages installed successfully."
else
    echo "❌ Error: Installation failed."
fi
