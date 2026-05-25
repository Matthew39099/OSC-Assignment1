#!/bin/bash

# ─── 1. GET LOCAL DIRECTORY ───────────────────────────────────────────────────
if [ -n "$1" ]; then
    directory="$1"
else
    read -p "Please enter a directory to zip: " directory
fi

# Validate local directory exists
if [ ! -d "$directory" ]; then
    echo "Error: Directory '$directory' does not exist. Exiting."
    exit 1
fi

# ─── 2. CREATE ARCHIVE ────────────────────────────────────────────────────────
basename_dir=$(basename "$directory")
output="/home/VISSMJ1/Assignment-1/OSC-Assignment/OSC-Assignment1/Task_2/backup-$(date +%Y-%m-%d).tar.gz"

echo "Compressing '$directory' into '$output'..."
tar -czvf "$output" -C "$directory" .

if [ $? -ne 0 ]; then
    echo "Error: Failed to create archive. Exiting."
    exit 1
fi

ls -lh "$output"

# List archive contents (no extraction)
tar -tzvf "$output"

# Count how many files are in the archive
tar -tzvf "$output" | wc -l

# Check for any obvious problems (e.g. absolute paths starting with /)
tar -tzvf "$output" | grep "^/" | head -5

# ─── 3. REMOTE SERVER DETAILS ─────────────────────────────────────────────────
read -p "Enter remote server IP or hostname: " remote_host
read -p "Enter SSH port (press Enter for default 22): " remote_port
remote_port=${remote_port:-22}
read -p "Enter target directory on remote server: " remote_dir

# ─── 4. UPLOAD TO REMOTE SERVER ───────────────────────────────────────────────
echo "Uploading '$output' to '$remote_host:$remote_dir'..."
scp -P "$remote_port" "$output" "VISSMJ1@$remote_host:$remote_dir"

if [ $? -ne 0 ]; then
    echo "Error: Upload failed. Possible causes:"
    echo "  - Remote server unreachable (network issue)"
    echo "  - Incorrect authentication credentials"
    echo "  - Invalid remote directory '$remote_dir'"
    exit 1
fi

echo "Upload successful!"

# ─── 5. VERIFY UPLOAD ─────────────────────────────────────────────────────────
echo "Verifying upload on remote server..."
ssh -p "$remote_port" "VISSMJ1@$remote_host" "ls $remote_dir"

if [ $? -ne 0 ]; then
    echo "Error: Could not verify upload on remote server."
    exit 1
fi

echo "Backup and upload completed successfully!"
