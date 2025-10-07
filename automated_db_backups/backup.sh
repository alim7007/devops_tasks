#!/bin/bash
set -euo pipefail

CONTAINER_NAME="todo-mongodb"
DB_NAME="todos"
DUMP_DIR_IN_CONTAINER="/tmp/mongo-todos-dump"
DUMP_DIR_LOCAL="/tmp/mongo-todos-dump"
BACKUP_FOLDER="backup"

# backblaze b2 (s3-compatible) settings
S3_ENDPOINT="https://s3.eu-central-003.backblazeb2.com"
S3_BUCKET="my-mongodb-backups"
S3_PREFIX="backups"

TIMESTAMP="$(date +"%Y%m%d_%H%M%S")"
BACKUP_FILE="mongo-${DB_NAME}_${TIMESTAMP}.tar.gz"
OUTFILE="${BACKUP_FOLDER}/${BACKUP_FILE}"
S3_URI="s3://${S3_BUCKET}/${S3_PREFIX}/${BACKUP_FILE}"

mkdir -p "${BACKUP_FOLDER}"

echo "Starting backup of DB '${DB_NAME}' from container '${CONTAINER_NAME}'..."
docker exec "${CONTAINER_NAME}" mongodump --db="${DB_NAME}" --out="${DUMP_DIR_IN_CONTAINER}"
docker cp "${CONTAINER_NAME}:${DUMP_DIR_IN_CONTAINER}" "${DUMP_DIR_LOCAL}"

echo "Compressing dump to '${OUTFILE}' ..."
if tar -czf "${OUTFILE}" -C "${DUMP_DIR_LOCAL}" .; then
  echo "Backup created at '${OUTFILE}'. Uploading to ${S3_URI} ..."
  aws s3 cp "${OUTFILE}" "${S3_URI}" --endpoint-url "${S3_ENDPOINT}"
#  i think this better: aws s3 cp "${OUTFILE}" --endpoint-url "${S3_ENDPOINT}/${S3_BUCKET}"
  echo "Upload done: ${S3_URI}"
else
  echo "Backup failed. Removing partial file."
  rm -f "${OUTFILE}" || true
  exit 1
fi

echo "Finished."


# You add this yourself
# What if mongodump fails?
# What if upload fails?
# Should script exit on error?
# Log messages for debugging