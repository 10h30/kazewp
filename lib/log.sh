#!/bin/bash

# Get the directory of the main script that sources this file
MAIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_FILE="$MAIN_DIR/kazewp.log"

# Create log file if it doesn't exist
touch "$LOG_FILE"

# Ensure log file is writable
if [ ! -w "$LOG_FILE" ]; then
    echo "Error: Cannot write to log file $LOG_FILE"
    exit 1
fi

# Function to add timestamp to log file
add_timestamp() {
    echo -e "\n========== $(date '+%Y-%m-%d %H:%M:%S') ==========" >> "$LOG_FILE"
}

# Save original file descriptors
exec 3>&1
exec 4>&2

# Add timestamp to log file
add_timestamp

# Setup logging while preserving read -p functionality:
# Use process substitution for logging
exec 1> >(tee >(sed 's/\x1B\[[0-9;]*[JKmsu]//g' >> "$LOG_FILE"))
exec 2> >(tee >(sed 's/\x1B\[[0-9;]*[JKmsu]//g' >> "$LOG_FILE"))

# Restore original stdout for read commands
export BASH_READ_FD=3