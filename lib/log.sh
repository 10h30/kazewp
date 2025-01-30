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

# Function to strip ANSI color codes
strip_colors() {
    sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g"
}

# Redirect all output to both the terminal and the log file (without colors)
exec > >(tee -a >(strip_colors >> "$LOG_FILE"))
exec 2> >(tee -a >(strip_colors >> "$LOG_FILE") >&2)