#!/bin/bash
process_user() {
    local email="$1"
    local birth_date="$2"
    local groups_input="$3"
    local shared_folder="$4"

    log_message "Processing: $email"

    # Step 1: Generate username
    local username
    username=$(generate_username "$email")
    log_message "Username: $username"

    # Step 2: Skip if user already exists
    if id "$username" &>/dev/null; then
        console_message "SKIP: $username already exists."
        log_message "SKIP: $username already exists."
        return 1
    fi

    # Step 3: Derive password from birth date (YYYYMM format)
    # Spec uses YYYY/MM/DD format so replace / with -
    local birth_date_fmt="${birth_date//\//-}"
    local password
    password=$(date -d "$birth_date_fmt" +'%Y%m' 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        log_message "ERROR: Invalid date '$birth_date' for $email."
        console_message "ERROR: Invalid date '$birth_date' for $email — skipping."
        return 1
    fi

    # Step 4: Hash password and create account
    local encrypted_pass
    encrypted_pass=$(openssl passwd -6 "$password")
    sudo useradd -m -s /bin/bash -p "$encrypted_pass" "$username"
    if [[ $? -ne 0 ]]; then
        log_message "ERROR: useradd failed for $username."
        console_message "ERROR: Failed to create user '$username'."
        return 1
    fi
    log_message "User $username created."

    # Step 5: Force password reset on first login
    sudo chage -d 0 "$username"
    log_message "Password expiry set for $username (must change on first login)."

    # Step 6: Process secondary groups
    if [[ -n "$groups_input" ]]; then
        IFS=':' read -ra groups_array <<< "$groups_input"
        for group in "${groups_array[@]}"; do
            group="$(echo "$group" | xargs)"
            [[ -z "$group" ]] && continue
            create_group "$group"
            sudo usermod -aG "$group" "$username"
            log_message "Added $username to group: $group"
        done
    fi

    # Step 7: Set up shared folder and symbolic link
    if [[ -n "$shared_folder" ]]; then
        local folder_group
        folder_group=$(basename "$shared_folder")
        create_group "$folder_group"
        sudo usermod -aG "$folder_group" "$username"
        setup_shared_folder "$shared_folder" "$folder_group"
        local user_home
        user_home=$(getent passwd "$username" | cut -d: -f6)
        sudo ln -sf "$shared_folder" "$user_home/shared"
        sudo chown -h "$username:$username" "$user_home/shared"
        log_message "Symlink ~/shared -> $shared_folder created for $username."
    fi

    # Step 8: Add alias for sudo users
    if [[ "$groups_input" == *"sudo"* ]]; then
        local user_home
        user_home=$(getent passwd "$username" | cut -d: -f6)
        local alias_file="$user_home/.bash_alias"
        sudo touch "$alias_file"
        sudo chown "$username:$username" "$alias_file"
        echo "alias myls='ls -al'" | sudo tee -a "$alias_file" >/dev/null
        log_message "Alias 'myls' added to $alias_file for sudo user $username."
    fi

    # Step 9: Console summary
    local user_home
    user_home=$(getent passwd "$username" | cut -d: -f6)
    echo ""
    echo "  User created: $username"
    echo "    Home:       $user_home"
    echo "    Groups:     $groups_input"
    [[ -n "$shared_folder" ]] && echo "    Shared:     $shared_folder"
    [[ -n "$shared_folder" ]] && echo "    Symlink:    $user_home/shared -> $shared_folder"
    [[ "$groups_input" == *"sudo"* ]] && echo "    Alias:      myls added to .bash_alias"

    log_message "Setup complete for: $username"
    return 0
}
