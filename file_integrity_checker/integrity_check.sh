#!/bin/bash

# Configuration
HASH_FILE="hashes.json"
HASH_ALGO="sha256sum"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if path exists
validate_path() {
    local path="$1"
    if [[ ! -e "$path" ]]; then
        echo -e "${RED}Error: Path does not exist: $path${NC}"
        exit 1
    fi
}

# Determine if path is a file or directory
is_file_or_dir() {
    local path="$1"
    if [[ -f "$path" ]]; then
        echo "file"
    elif [[ -d "$path" ]]; then
        echo "dir"
    else
        echo "unknown"
    fi
}

# Get list of all files (handles both file and directory)
get_all_files() {
    local path="$1"
    local type=$(is_file_or_dir "$path")
    
    if [[ "$type" == "file" ]]; then
        echo "$path"
    elif [[ "$type" == "dir" ]]; then
        find "$path" -type f
    fi
}

# Calculate SHA-256 hash of a file
hash_file() {
    local filepath="$1"
    sha256sum "$filepath" | awk '{print $1}'
}

# Initialize hash file if it doesn't exist
init_hash_file() {
    if [[ ! -f "$HASH_FILE" ]]; then
        echo "{}" > "$HASH_FILE"
    fi
}

# Save hash to JSON file
save_hash() {
    local filepath="$1"
    local hash="$2"
    init_hash_file
    
    # Use jq to update JSON (you'll need to install jq)
    local temp_file=$(mktemp)
    jq --arg path "$filepath" --arg hash "$hash" '. + {($path): $hash}' "$HASH_FILE" > "$temp_file"
    mv "$temp_file" "$HASH_FILE"
}

# Load hash from JSON file
load_hash() {
    local filepath="$1"
    if [[ ! -f "$HASH_FILE" ]]; then
        echo ""
        return
    fi
    
    jq -r --arg path "$filepath" '.[$path] // ""' "$HASH_FILE"
}

# Initialize and store hashes
cmd_init() {
    local path="$1"
    validate_path "$path"
    
    echo "Initializing integrity database for: $path"
    
    local count=0
    while IFS= read -r file; do
        echo "Hashing: $file"
        local hash=$(hash_file "$file")
        save_hash "$file" "$hash"
        ((count++))
    done < <(get_all_files "$path")
    
    echo -e "${GREEN}Successfully hashed $count file(s).${NC}"
}

# Check file integrity
cmd_check() {
    local path="$1"
    validate_path "$path"
    
    local modified=0
    local unmodified=0
    
    while IFS= read -r file; do
        local current_hash=$(hash_file "$file")
        local stored_hash=$(load_hash "$file")
        
        if [[ -z "$stored_hash" ]]; then
            echo -e "${YELLOW}$file: Not tracked (run init first)${NC}"
        elif [[ "$current_hash" == "$stored_hash" ]]; then
            echo -e "${GREEN}$file: Unmodified${NC}"
            ((unmodified++))
        else
            echo -e "${RED}$file: Modified (Hash mismatch)${NC}"
            ((modified++))
        fi
    done < <(get_all_files "$path")
    
    echo ""
    echo "Summary: $unmodified unmodified, $modified modified"
}

# Update stored hash for a file
cmd_update() {
    local path="$1"
    validate_path "$path"
    
    while IFS= read -r file; do
        local new_hash=$(hash_file "$file")
        save_hash "$file" "$new_hash"
        echo -e "${GREEN}$file: Hash updated successfully${NC}"
    done < <(get_all_files "$path")
}

########################

# Show usage information
show_usage() {
    echo "Usage: $0 <command> <path>"
    echo ""
    echo "Commands:"
    echo "  init <path>    Initialize and store hashes for files"
    echo "  check <path>   Check file integrity against stored hashes"
    echo "  update <path>  Update stored hashes for files"
    echo ""
    echo "Examples:"
    echo "  $0 init /var/log"
    echo "  $0 check /var/log/syslog"
    echo "  $0 update /var/log/auth.log"
}

# Main script logic
main() {
    if [[ $# -lt 2 ]]; then
        show_usage
        exit 1
    fi
    
    local command="$1"
    local path="$2"
    
    case "$command" in
        init)
            cmd_init "$path"
            ;;
        check)
            cmd_check "$path"
            ;;
        update)
            cmd_update "$path"
            ;;
        *)
            echo -e "${RED}Error: Unknown command '$command'${NC}"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"