#!/bin/bash
generate_username() {
    local email="$1"
    # Split at '@' to get the local part, e.g., "alice.smith"
    local name_part="${email%@*}"
    # Edge case: no dot -> use the whole local part lowercased
    if [[ "$name_part" != *.* ]]; then
        echo "$name_part" | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]'
        return 0
    fi
    # Split into first name and surname at the first dot
    local first_name="${name_part%%.*}"    # everything before the first dot
    local surname="${name_part#*.}"        # everything after the first dot
    surname="${surname%%.*}"               # drop any further dots (a.b.c -> b)
    # Sanitize: keep alphanumeric only
    first_name=$(echo "$first_name" | tr -cd '[:alnum:]')
    surname=$(echo "$surname" | tr -cd '[:alnum:]')
    # First letter of surname, lowercased
    local first_letter
    first_letter=$(echo "${surname:0:1}" | tr '[:upper:]' '[:lower:]')
    # Capitalize first letter of first name
    local cap_first
    cap_first="$(tr '[:lower:]' '[:upper:]' <<< "${first_name:0:1}")${first_name:1}"
    # Result: e.g., linus.torvalds -> tLinus
    echo "${first_letter}${cap_first}"
}
