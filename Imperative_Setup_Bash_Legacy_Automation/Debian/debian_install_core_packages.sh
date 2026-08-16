#!/bin/bash

# ==============================================================================
# PROXMOX / DEBIAN UTILITY INSTALLER (ANNOTATED)
# ==============================================================================
# This script installs a curated list of packages.
# ==============================================================================

# 1. ROOT PRIVILEGE CHECK
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: This script must be run as root."
  exit 1
fi

# ------------------------------------------------------------------------------
# 2. DEFINE PACKAGE LIST
# ------------------------------------------------------------------------------
PACKAGES=(
    # --- System Monitoring & Process Management ---
    htop            # Interactive process viewer
    cron            # Task scheduler
    rclone          # Cloud storage sync tool
    btop            # Modern resource monitor (CPU/RAM/Disk)
    iotop           # Disk I/O usage per process
    sysstat         # System performance stats (sar, iostat)
    dstat           # Versatile resource statistics tool
    lsof            # List open files
    strace          # Trace system calls

    # --- Network Utilities ---
    nmap            # Network scanner
    curl            # Data transfer (HTTP/S)
    iftop           # Bandwidth usage viewer
    nload           # Traffic monitor
    iperf3          # Network throughput benchmark
    tcpdump         # Packet analyzer
    traceroute      # Route path tracing
    mtr             # Network diagnostic tool (ping + traceroute)
    bind9-dnsutils  # DNS tools (dig, nslookup)
    whois           # IP/Domain registration info
    socat           # Multipurpose relay (SOcket CAT)
    fail2ban        # Intrusion prevention
    ufw             # Uncomplicated Firewall

    # --- Disk & Hardware Management ---
    hdparm          # SATA/IDE device parameters
    fio             # Flexible I/O tester
    gdisk           # GPT partition tool
    parted          # Partition manipulation
    smartmontools   # S.M.A.R.T disk monitoring
    nvme-cli        # NVMe management
    lm-sensors      # Hardware sensors (temp/voltage)
    ncdu            # Disk usage analyzer (ncurses)

    # --- Development & Automation ---
    git             # Version control
    pipx            # Python application installer
    python3-full    # Python runtime

    # --- Editors & Terminal ---
    vim             # Advanced text editor
    neovim          # Hyper-extensible Vim-based editor
    tmux            # Terminal multiplexer
    zsh             # Z shell
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

    # --- Data Processing ---
    jq              # Command-line JSON processor
    yq              # YAML processor
    hexedit         # Hexadecimal editor
    binutils        # Binary tools (strings, strip, etc.)

    # --- Stress Testing ---
    stress          # Workload generator
    stress-ng       # Advanced stress tool
    apache2-utils   # Web server benchmark (ab)

    # --- Utilities ---
    watch           # Execute a program periodically
    tealdeer        # Simplified man pages
    hwinfo          # Lists details about your system, CPU, graphics, audio, networking, drives, partitions, sensors, and more
    lshw            # Lists details about your system, CPU, graphics, audio, networking, drives, partitions, sensors, and more
)

# ------------------------------------------------------------------------------
# 3. UPDATE REPOSITORIES
# ------------------------------------------------------------------------------
echo "Updating package lists..."
apt update

# ------------------------------------------------------------------------------
# 4. INSTALL PACKAGES
# ------------------------------------------------------------------------------
echo "Installing ${#PACKAGES[@]} packages..."

# EXPLANATION OF FLAGS:
# 1. DEBIAN_FRONTEND=noninteractive
#    This environment variable tells apt to suppress "Configuration" pop-ups
#    (blue screens) that ask for user input (e.g., "Select Keyboard Layout").
#    It forces the system to accept default settings so the script doesn't hang.
#
# 2. -y (Yes)
#    This flag automatically answers "Yes" to the prompt:
#    "Do you want to continue? [Y/n]".
# Combined, these ensure a "Zero-Touch" installation.

DEBIAN_FRONTEND=noninteractive apt install -y "${PACKAGES[@]}"
apt update

# ------------------------------------------------------------------------------
# 5. VERIFICATION
# ------------------------------------------------------------------------------
# "$?" is a variable that holds the "Exit Code" of the last command run.
# - 0 means Success.
# - Any other number (1-255) means Error.
if [ $? -eq 0 ]; then
    echo "✅ Success! All packages installed successfully."
else
    echo "❌ Error: Installation failed."
fi
