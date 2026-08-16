#!/bin/bash

# --- Configuration ---
# Local mount point of the share/HDD you want to keep alive.
SHARE_PATH="/mnt/shared_storage/HDD_StopSpinDown"
FILE_NAME="keep_alive_data"
DATA_FILE="$SHARE_PATH/$FILE_NAME"
# IMPORTANT: Schedule this script in your cron job at an interval
# shorter than your HDD's spin-down timeout (e.g., every 5 minutes).

# --- Script Logic ---

# Check if the share path is mounted and accessible
if [ ! -d "$SHARE_PATH" ]; then
    echo "Error: Share path $SHARE_PATH does not exist or is not mounted."
    exit 1
fi

# 1. Check for and Create the Persistent Data File (Initial ONE-TIME WRITE)
# If the file does not exist, create it once with a single random digit.
if [ ! -f "$DATA_FILE" ]; then
    echo "Info: Data file not found. Creating persistent 1-byte file with a random digit: $DATA_FILE"

    # Generate one random digit (0-9) and write it to the file without a newline.
    # We use 'shuf' for randomness and 'echo -n' to prevent writing a newline character.
    echo -n $(shuf -i 0-9 -n 1) > "$DATA_FILE"

    if [ $? -ne 0 ]; then
        echo "Error: Failed to create initial file $DATA_FILE."
        exit 1
    fi
fi

# 2. Perform the "Keep Alive" Write Operation (PERIODIC OVERWRITE)
# Every time the script runs, overwrite the existing file with a new single random digit.
# This definitive WRITE operation reliably resets the HDD idle timer with minimal I/O.
echo -n $(shuf -i 0-9 -n 1) > "$DATA_FILE"

# Check the exit status of the overwrite command
if [ $? -ne 0 ]; then
    echo "Warning: Overwrite operation failed. The disk may be inaccessible or have issues."
    # The script exits here; the next execution will attempt the overwrite again.
    exit 1
fi

# The script finishes successfully
exit 0
