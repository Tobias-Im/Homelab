#!/bin/bash

# ==============================================================================
# SET SWAPPINESS TO 1 (NO PROMPTS)
# ==============================================================================
# Forces the kernel to avoid using Swap unless RAM is completely full.
# ==============================================================================


echo "Setting Swappiness to 1..."

# 2. WRITE CONFIGURATION (Permanent)
# We use a dedicated file in /etc/sysctl.d/ so it survives updates
echo "vm.swappiness=1" > /etc/sysctl.d/99-swappiness.conf

# 3. APPLY CHANGES (Immediate)
sysctl --system > /dev/null 2>&1

# 4. VERIFY
CURRENT_VAL=$(cat /proc/sys/vm/swappiness)

if [ "$CURRENT_VAL" -eq 1 ]; then
    echo "✅ Success! Swappiness is now set to $CURRENT_VAL."
else
    echo "❌ Failed. Current value is still $CURRENT_VAL."
fi