#!/bin/bash
download_file() {
    local uri="$1"
    local temp_file="downloaded_users_$(date +%s).csv"
    console_message "Downloading from $uri..."
    log_message "Attempting download from $uri"
    if command -v wget &>/dev/null; then
        wget -q "$uri" -O "$temp_file"
    elif command -v curl &>/dev/null; then
        curl -s "$uri" -o "$temp_file"
    else
        echo "Error: Neither wget nor curl found." >&2
        log_message "ERROR: Neither wget nor curl found."
        exit 1
    fi
    if [[ $? -ne 0 || ! -f "$temp_file" ]]; then
        echo "Error: Download failed from $uri" >&2
        log_message "ERROR: Download failed from $uri"
        exit 1
    fi
    log_message "Download successful: $temp_file"
    validate_local_file "$temp_file"
}
