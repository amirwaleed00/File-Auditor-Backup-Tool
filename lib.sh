#!/bin/bash

# Display an information message.
# Show the message to the user.
log_info() {
    echo "[INFO] $1"
}


# Display an error message.
# Show errors to the user.
log_error() {
    echo "[ERROR] $1" >&2
}


# Record an action with its date and time.
# Save the action in the log file.
log_action() {
    local action="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $action" >> "$LOG_FILE"
}


# Check if the directory exists.
# Stop the program if it does not exist.
require_dir() {
    local dir="$1"

    if [ ! -d "$dir" ]; then
        log_error "Directory does not exist: $dir"
        exit 1
    fi
}
