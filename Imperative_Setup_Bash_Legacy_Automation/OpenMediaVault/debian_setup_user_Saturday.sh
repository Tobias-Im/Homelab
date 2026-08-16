#!/bin/bash

# ==============================================================================
# CREATE AND CONFIGURE USER: Saturday
# ==============================================================================
# Checks if the user 'Saturday' exists. If not, creates the user.
# Adds the user to the 'sudo' group and 'docker' group.
# ==============================================================================

# 1. ROOT PRIVILEGE CHECK
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: This script must be run as root."
  exit 1
fi

TARGET_USER="Saturday"

echo "========================================================"
echo "🚀 CONFIGURING USER: $TARGET_USER"
echo "========================================================"

# Step 1: Check if the user exists
if id "$TARGET_USER" &>/dev/null; then
    echo ">> User '$TARGET_USER' already exists."
else
    echo ">> User '$TARGET_USER' does not exist. Creating now..."
    # adduser will automatically prompt you to type a secure password for the new user
    adduser --gecos "" "$TARGET_USER"
fi

# Step 2: Ensure the required groups actually exist on this system
if ! getent group sudo &>/dev/null; then
    echo ">> Warning: 'sudo' group missing. Creating it..."
    groupadd sudo
fi

if ! getent group docker &>/dev/null; then
    echo ">> Warning: 'docker' group missing. Creating it..."
    groupadd docker
fi

# Step 3: Assign the user to both groups
echo ">> Adding '$TARGET_USER' to sudo and docker groups..."
usermod -aG sudo,docker "$TARGET_USER"

echo "========================================================"
echo "🎉 SUCCESS: User '$TARGET_USER' is configured!"
echo "   - They can now run admin commands with 'sudo'"
echo "   - They can now run Docker containers without root"
echo "========================================================"
