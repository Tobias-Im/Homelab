#!/bin/bash

# ==============================================================================
# CONFIGURE SHELL ALIASES
# ==============================================================================

# 1. Define the alias
ALIAS_LINE="alias ll='ls -ahl'"
CONFIG_FILE="/etc/bash.bashrc"

# 2. Check if it already exists (Prevents duplicates)
if grep -Fq "$ALIAS_LINE" "$CONFIG_FILE"; then
    echo "✅ Alias 'll' already exists in $CONFIG_FILE"
else
    echo "Adding 'll' alias to $CONFIG_FILE..."
    echo "$ALIAS_LINE" >> "$CONFIG_FILE"
    echo "✅ Alias added."
fi

# 3. Reload Configuration
# Note: When run inside a script, 'source' only updates the script's own session.
# We run it anyway as requested, but we also remind you to do it in your shell.
source "$CONFIG_FILE"

echo "========================================================================"
echo "⚠️  IMPORTANT:"
echo "To enable the 'll' command in your CURRENT terminal window, run:"
echo "   source /etc/bash.bashrc"
echo "========================================================================"