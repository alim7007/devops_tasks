#!/bin/bash

# Exit on error, undefined variables, and pipe failures
set -euo pipefail

# Configuration
CONTAINER_NAME="todo-mongodb"
API_CONTAINER_NAME="todo-api"
DB_NAME="todos"
RESTORE_DIR_LOCAL="/tmp/mongo-restore"
RESTORE_DIR_IN_CONTAINER="/tmp/mongo-restore"
BACKUP_DIR="/opt/backups/mongodb"

# Backblaze B2 settings
S3_ENDPOINT="https://s3.eu-central-003.backblazeb2.com"
S3_BUCKET="my-mongodb-backups"
S3_PREFIX="backups"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR $(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" >&2
}

warn() {
    echo -e "${YELLOW}[WARN $(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Cleanup function
cleanup() {
    log "Cleaning up temporary files..."
    rm -rf "${RESTORE_DIR_LOCAL}" || true
}

trap cleanup EXIT

# List available backups from B2
list_backups() {
    log "Fetching available backups from B2..."
    aws s3 ls "s3://${S3_BUCKET}/${S3_PREFIX}/" \
        --endpoint-url "${S3_ENDPOINT}" \
        | grep "mongo-${DB_NAME}_" \
        | awk '{print $4}' \
        | sort -r
}

# List local backups
list_local_backups() {
    log "Available local backups:"
    if [ -d "${BACKUP_DIR}" ]; then
        ls -1t "${BACKUP_DIR}"/mongo-${DB_NAME}_*.tar.gz 2>/dev/null || echo "No local backups found"
    else
        echo "No local backup directory found"
    fi
}

# Download backup from B2
download_backup() {
    local backup_file=$1
    local s3_uri="s3://${S3_BUCKET}/${S3_PREFIX}/${backup_file}"
    local local_file="${BACKUP_DIR}/${backup_file}"
    
    log "Downloading ${backup_file} from B2..."
    mkdir -p "${BACKUP_DIR}"
    
    if aws s3 cp "${s3_uri}" "${local_file}" \
        --endpoint-url "${S3_ENDPOINT}" \
        --no-progress; then
        log "✓ Downloaded to ${local_file}"
        echo "${local_file}"
    else
        error "Failed to download backup from B2"
        return 1
    fi
}

# Restore database from backup file
restore_database() {
    local backup_file=$1
    
    # Check if file exists and is not empty
    if [ ! -f "${backup_file}" ] || [ ! -s "${backup_file}" ]; then
        error "Backup file does not exist or is empty: ${backup_file}"
        return 1
    fi
    
    log "=== Starting MongoDB Restore ==="
    log "Backup file: ${backup_file}"
    log "Database: ${DB_NAME}"
    
    # Check if containers are running
    if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        error "MongoDB container '${CONTAINER_NAME}' is not running!"
        return 1
    fi
    
    # Step 1: Stop API container to prevent writes during restore
    log "Stopping API container to prevent writes..."
    if docker ps --format '{{.Names}}' | grep -q "^${API_CONTAINER_NAME}$"; then
        docker stop "${API_CONTAINER_NAME}"
        log "✓ API container stopped"
    else
        warn "API container not running, skipping..."
    fi
    
    # Step 2: Extract tarball
    log "Extracting backup tarball..."
    mkdir -p "${RESTORE_DIR_LOCAL}"
    if ! tar -xzf "${backup_file}" -C "${RESTORE_DIR_LOCAL}"; then
        error "Failed to extract tarball!"
        docker start "${API_CONTAINER_NAME}" 2>/dev/null || true
        return 1
    fi
    log "✓ Tarball extracted"
    
    # Step 3: Copy extracted dump to container
    log "Copying dump to MongoDB container..."
    if ! docker cp "${RESTORE_DIR_LOCAL}/." "${CONTAINER_NAME}:${RESTORE_DIR_IN_CONTAINER}"; then
        error "Failed to copy dump to container!"
        docker start "${API_CONTAINER_NAME}" 2>/dev/null || true
        return 1
    fi
    log "✓ Dump copied to container"
    
    # Step 4: Drop existing database (optional, uncomment if you want clean restore)
    warn "Dropping existing database '${DB_NAME}'..."
    read -p "Are you sure you want to drop the existing database? (yes/no): " confirm
    if [ "${confirm}" = "yes" ]; then
        docker exec "${CONTAINER_NAME}" mongosh --eval "db.getSiblingDB('${DB_NAME}').dropDatabase()" || warn "Could not drop database (might not exist)"
        log "✓ Database dropped"
    else
        info "Skipping database drop. Data will be merged/overwritten."
    fi
    
    # Step 5: Run mongorestore
    log "Running mongorestore..."
    if docker exec "${CONTAINER_NAME}" mongorestore \
        --db="${DB_NAME}" \
        "${RESTORE_DIR_IN_CONTAINER}/${DB_NAME}" 2>&1 | grep -v "writing"; then
        log "✓ Database restored successfully"
    else
        error "mongorestore failed!"
        docker start "${API_CONTAINER_NAME}" 2>/dev/null || true
        return 1
    fi
    
    # Step 6: Cleanup container restore directory
    log "Cleaning up container restore files..."
    docker exec "${CONTAINER_NAME}" rm -rf "${RESTORE_DIR_IN_CONTAINER}" || true
    
    # Step 7: Start API container
    log "Starting API container..."
    if docker start "${API_CONTAINER_NAME}"; then
        log "✓ API container started"
        sleep 3  # Wait for container to be ready
        log "Waiting for API to be ready..."
        for i in {1..10}; do
            if docker exec "${API_CONTAINER_NAME}" wget -q --spider http://localhost:3000/ 2>/dev/null; then
                log "✓ API is responding"
                break
            fi
            sleep 2
        done
    else
        error "Failed to start API container!"
        return 1
    fi
    
    log "=== Restore Completed Successfully ==="
}

# Interactive menu
show_menu() {
    echo ""
    echo "======================================"
    echo "   MongoDB Restore Script"
    echo "======================================"
    echo "1. List backups on B2 (remote)"
    echo "2. List local backups"
    echo "3. Download latest backup from B2"
    echo "4. Restore from local backup"
    echo "5. Download and restore latest backup"
    echo "6. Exit"
    echo "======================================"
}

# Main function
main() {
    # If backup file provided as argument, restore directly
    if [ $# -eq 1 ]; then
        restore_database "$1"
        exit $?
    fi
    
    # Interactive mode
    while true; do
        show_menu
        read -p "Choose an option: " choice
        
        case $choice in
            1)
                list_backups
                ;;
            2)
                list_local_backups
                ;;
            3)
                backups=($(list_backups))
                if [ ${#backups[@]} -eq 0 ]; then
                    error "No backups found on B2"
                else
                    latest="${backups[0]}"
                    log "Latest backup: ${latest}"
                    download_backup "${latest}"
                fi
                ;;
            4)
                list_local_backups
                echo ""
                read -p "Enter backup filename (or full path): " backup_file
                if [[ "${backup_file}" != /* ]]; then
                    backup_file="${BACKUP_DIR}/${backup_file}"
                fi
                restore_database "${backup_file}"
                ;;
            5)
                backups=($(list_backups))
                if [ ${#backups[@]} -eq 0 ]; then
                    error "No backups found on B2"
                else
                    latest="${backups[0]}"
                    log "Latest backup: ${latest}"
                    local_file=$(download_backup "${latest}")
                    if [ $? -eq 0 ]; then
                        restore_database "${local_file}"
                    fi
                fi
                ;;
            6)
                log "Exiting..."
                exit 0
                ;;
            *)
                error "Invalid option"
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Run main
main "$@"