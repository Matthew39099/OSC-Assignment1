#!/bin/bash
setup_shared_folder() {
    local folder_path="$1"
    local group_name="$2"
    [[ -z "$folder_path" ]] && return 0
    log_message "Setting up shared folder: $folder_path (group: $group_name)"
    if [[ ! -d "$folder_path" ]]; then
        sudo mkdir -p "$folder_path"
        if [[ $? -ne 0 ]]; then
            log_message "ERROR: mkdir failed for $folder_path."
            console_message "ERROR: Failed to create shared folder '$folder_path'."
            return 1
        fi
    fi
    sudo chown root:"$group_name" "$folder_path"
    sudo chmod 770 "$folder_path"
    sudo chmod g+s "$folder_path"
    log_message "Permissions set on $folder_path (770, setgid, group: $group_name)."
}
