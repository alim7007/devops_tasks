#!/bin/bash
set -euo pipefail

CONTAINER_NAME="todo-mongodb"
DB_NAME="todos"
DUMP_DIR_IN_CONTAINER="/tmp/mongo-backup-dump"
DUMP_DIR_LOCAL="/tmp/mongo-backup-dump"
BACKUP_FOLDER="/opt/backups/mongodb"

# backblaze b2 (s3-compatible) settings
S3_ENDPOINT="https://s3.eu-central-003.backblazeb2.com"
S3_BUCKET="my-mongodb-backups"
S3_PREFIX="backups"

TIMESTAMP="$(date +"%Y%m%d_%H%M%S")"
BACKUP_FILE="mongo-${DB_NAME}_${TIMESTAMP}.tar.gz"
LOCAL_BACKUP="${BACKUP_FOLDER}/${BACKUP_FILE}"
S3_URI="s3://${S3_BUCKET}/${S3_PREFIX}/${BACKUP_FILE}"

# Retention: Keep only last N backups locally
MAX_LOCAL_BACKUPS=7

# Color output for better readability
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR $(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" >&2
}

warn() {
    echo -e "${YELLOW}[WARN $(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

# Cleanup function
cleanup() {
    log "Cleaning up temporary files..."
    rm -rf "${DUMP_DIR_LOCAL}" || true
}

# Set trap to cleanup on exit
trap cleanup EXIT

# Main backup process
main() {
    log "=== Starting MongoDB Backup ==="
    log "Database: ${DB_NAME}"
    log "Container: ${CONTAINER_NAME}"
    
    # Check if container is running
    if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        error "Container '${CONTAINER_NAME}' is not running!"
        exit 1
    fi
    
    # Create backup directory
    mkdir -p "${BACKUP_DIR}"
    
    # Step 1: Run mongodump inside container
    log "Running mongodump inside container..."
    if ! docker exec "${CONTAINER_NAME}" mongodump \
        --db="${DB_NAME}" \
        --out="${DUMP_DIR_IN_CONTAINER}" 2>&1 | grep -v "writing"; then
        error "mongodump failed!"
        exit 1
    fi
    log "✓ mongodump completed"
    
    # Step 2: Copy dump from container to host
    log "Copying dump from container to host..."
    if ! docker cp "${CONTAINER_NAME}:${DUMP_DIR_IN_CONTAINER}" "${DUMP_DIR_LOCAL}"; then
        error "Failed to copy dump from container!"
        exit 1
    fi
    log "✓ Dump copied to host"
    
    # Step 3: Create compressed tarball
    log "Creating compressed tarball: ${BACKUP_FILE}"
    if ! tar -czf "${LOCAL_BACKUP}" -C "${DUMP_DIR_LOCAL}" .; then
        error "Failed to create tarball!"
        rm -f "${LOCAL_BACKUP}" || true
        exit 1
    fi
    
    # Verify tarball was created and has content
    if [ ! -f "${LOCAL_BACKUP}" ] || [ ! -s "${LOCAL_BACKUP}" ]; then
        error "Backup file is missing or empty!"
        exit 1
    fi
    
    BACKUP_SIZE=$(du -h "${LOCAL_BACKUP}" | cut -f1)
    log "✓ Tarball created (Size: ${BACKUP_SIZE})"
    
    # Step 4: Upload to Backblaze B2
    log "Uploading to B2: ${S3_URI}"
    if ! aws s3 cp "${LOCAL_BACKUP}" "${S3_URI}" \
        --endpoint-url "${S3_ENDPOINT}" \
        --no-progress 2>&1; then
        error "Upload to B2 failed!"
        exit 1
    fi
    log "✓ Upload completed successfully"
    
    # Step 5: Verify upload by checking if file exists
    log "Verifying upload..."
    if aws s3 ls "${S3_URI}" --endpoint-url "${S3_ENDPOINT}" > /dev/null 2>&1; then
        log "✓ Backup verified on B2"
    else
        warn "Could not verify backup on B2 (file might still be uploading)"
    fi
    
    # Step 6: Cleanup old local backups (keep last N)
    log "Cleaning up old local backups (keeping last ${MAX_LOCAL_BACKUPS})..."
    cd "${BACKUP_DIR}"
    ls -t mongo-${DB_NAME}_*.tar.gz 2>/dev/null | tail -n +$((MAX_LOCAL_BACKUPS + 1)) | xargs -r rm -f
    REMAINING=$(ls -1 mongo-${DB_NAME}_*.tar.gz 2>/dev/null | wc -l)
    log "✓ Local backups: ${REMAINING} file(s)"
    
    # Step 7: Cleanup temporary container dump
    log "Cleaning up container dump..."
    docker exec "${CONTAINER_NAME}" rm -rf "${DUMP_DIR_IN_CONTAINER}" || true
    
    log "=== Backup Completed Successfully ==="
    log "Local: ${LOCAL_BACKUP}"
    log "Remote: ${S3_URI}"
}

main