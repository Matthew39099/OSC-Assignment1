#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---- Global state ----
LOG_FILE="user_manager_$(date +%Y%m%d_%H%M%S).log"
INPUT_FILE=""

# ---- Source all function modules ----
source "$SCRIPT_DIR/log_message.sh"
source "$SCRIPT_DIR/val_local_file.sh"
source "$SCRIPT_DIR/download_file.sh"
source "$SCRIPT_DIR/create_group.sh"
source "$SCRIPT_DIR/setup_shared_folder.sh"
source "$SCRIPT_DIR/generate_username.sh"
source "$SCRIPT_DIR/process_user.sh"

# ---- Main entry point ----
if [[ $# -eq 0 ]]; then
    read -rp "Enter local file path or URL: " source_input
    if [[ "$source_input" == http* ]]; then
        download_file "$source_input"
    else
        validate_local_file "$source_input"
    fi
else
    case "$1" in
        -f|--file) validate_local_file "$2" ;;
        -u|--uri)  download_file "$2" ;;
        *)
            echo "Usage: $0 [-f <csv_path>] | [-u <url>]" >&2
            exit 1
            ;;
    esac
fi

log_message "Input source confirmed: $INPUT_FILE"

# ---- Confirmation dialogue ----
total=$(tail -n +2 "$INPUT_FILE" | grep -c '\S')
echo ""
echo "============================================"
echo "  User Management Script"
echo "  Log file: $LOG_FILE"
echo "============================================"
echo ""
echo "  Found $total user(s) to process from: $INPUT_FILE"
echo ""
read -rp "  Proceed with user creation? [y/N]: " confirm
echo ""
if [[ "$confirm" != [yY] ]]; then
    echo "  Aborted."
    log_message "User aborted before processing."
    exit 0
fi

log_message "User confirmed. Beginning processing of $total users."

# ---- Parsing loop ----
# Handles variable number of group columns
# Format: email, birth_date, [group1, group2, ...], shared_folder
tail -n +2 "$INPUT_FILE" | while IFS=',' read -r email birth_date rest; do
    # Trim whitespace
    email="$(echo "$email" | xargs)"
    birth_date="$(echo "$birth_date" | xargs)"

    # Split remaining fields into array
    IFS=',' read -ra fields <<< "$rest"

    # Last field is shared folder, rest are groups
    shared_folder="$(echo "${fields[-1]}" | xargs)"
    unset 'fields[-1]'

    # Join remaining group fields with colon separator
    groups="$(IFS=':'; echo "${fields[*]}" | xargs)"

    process_user "$email" "$birth_date" "$groups" "$shared_folder"
done

echo ""
echo "============================================"
echo "  Processing complete. See $LOG_FILE for details."
echo "============================================"
log_message "Script completed."
