#!/bin/bash
validate_local_file() {
    local file_path="$1"
    if [[ ! -f "$file_path" ]]; then
        echo "Error: '$file_path' does not exist." >&2
        exit 1
    fi
    if [[ ! -r "$file_path" ]]; then
        echo "Error: '$file_path' is not readable." >&2
        exit 1
    fi
    if ! head -n 1 "$file_path" | grep -q ","; then
        echo "Error: '$file_path' does not look like a CSV file." >&2
        exit 1
    fi
    INPUT_FILE="$file_path"
    console_message "Input file validated: $INPUT_FILE"
    log_message "Input file validated: $INPUT_FILE"
}
