#!/bin/bash
set -euo pipefail

# Variables
DIRECTORY_TO_BACKUP="$1"
BACKUP_FOLDER="backup"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${DIRECTORY_TO_BACKUP##*/}_$TIMESTAMP.tar.gz"
OUTFILE="$BACKUP_FOLDER/$BACKUP_FILE"

# Create backup folder if it doesn't exist
mkdir -p "$BACKUP_FOLDER"

# Check if the directory exists
if [[ -d "$DIRECTORY_TO_BACKUP" ]]; then
    echo "Starting backup of '$DIRECTORY_TO_BACKUP'..."
    
    # Run tar and check status
    if tar -czf "$OUTFILE" -C "$DIRECTORY_TO_BACKUP" .; then
        echo "Backup created at '$OUTFILE'."
    else
        echo "Backup failed. Removing partial file."
        rm -f "$OUTFILE"
        exit 1
    fi
else
    echo "Error: Directory '$DIRECTORY_TO_BACKUP' does not exist."
    exit 1
fi
