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

# Function to strip ANSI color codes
strip_colors() {
    sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g"
}

# Save original file descriptors
exec 3>&1
exec 4>&2

# Add timestamp to log file
add_timestamp

# Redirect stdout and stderr to log file (without color codes) and also to the terminal (with colors)
exec 1> >(tee >(strip_colors >> "$LOG_FILE") >&3)
exec 2> >(tee >(strip_colors >> "$LOG_FILE") >&4)