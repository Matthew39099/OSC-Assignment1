#!/bin/bash
create_group() {
    local group_name="$1"
    if getent group "$group_name" &>/dev/null; then
        log_message "Group '$group_name' already exists. Skipping."
        return 0
    fi
    sudo groupadd "$group_name"
    if [[ $? -ne 0 ]]; then
        log_message "ERROR: Failed to create group '$group_name'."
        console_message "ERROR: Failed to create group '$group_name'."
        return 1
    fi
    log_message "Group '$group_name' created."
}
