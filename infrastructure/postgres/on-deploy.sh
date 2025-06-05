#!/bin/bash
set -e

# Configuration
: "${POSTGRES_HOST:=postgres}"
: "${POSTGRES_PORT:=5432}"
: "${TARGET_DB:=events}"
: "${POSTGRES_USER:?Must set POSTGRES_USER}"
: "${POSTGRES_PASSWORD:?Must set POSTGRES_PASSWORD}"
: "${EVENTS_MIGRATOR_POSTGRES_PASSWORD:?Must set EVENTS_MIGRATOR_POSTGRES_PASSWORD}"
: "${EVENTS_APP_POSTGRES_PASSWORD:?Must set EVENTS_APP_POSTGRES_PASSWORD}"

STACK_PREFIX="${STACK:+${STACK}__}" # adds __ to $STACK if it's non-empty
TARGET_DB="${STACK_PREFIX}events"
EVENTS_MIGRATOR_ROLE="${STACK_PREFIX}events_migrator"
EVENTS_APP_ROLE="${STACK_PREFIX}events_app"

# Install required tools
apt-get update
apt-get install -y curl

# Wait for PostgreSQL to be ready
until PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d postgres -c '\q' 2>/dev/null; do
  echo "Waiting for PostgreSQL at ${POSTGRES_HOST}:${POSTGRES_PORT}..."
  sleep 2
done

# Check if database exists
echo "Checking if database '$TARGET_DB' exists..."
DB_EXISTS=$(PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname = '$TARGET_DB';")

if [[ "$DB_EXISTS" == "1" ]]; then
  echo "Database '$TARGET_DB' already exists. Skipping init."
else
  echo "Database '$TARGET_DB' does not exist. Initializing..."

  PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d postgres <<EOF
CREATE DATABASE "$TARGET_DB";

CREATE ROLE "$EVENTS_MIGRATOR_ROLE" WITH LOGIN PASSWORD '${EVENTS_MIGRATOR_POSTGRES_PASSWORD}';
CREATE ROLE "$EVENTS_APP_ROLE" WITH LOGIN PASSWORD '${EVENTS_APP_POSTGRES_PASSWORD}';

GRANT CONNECT ON DATABASE "$TARGET_DB" TO "$EVENTS_MIGRATOR_ROLE", "$EVENTS_APP_ROLE";
EOF

  PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$TARGET_DB" <<EOF
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
REVOKE CREATE ON SCHEMA public FROM "$EVENTS_MIGRATOR_ROLE";

CREATE SCHEMA app AUTHORIZATION "$EVENTS_MIGRATOR_ROLE";

ALTER ROLE "$EVENTS_MIGRATOR_ROLE" SET search_path = app;
ALTER ROLE "$EVENTS_APP_ROLE" SET search_path = app;
EOF

  echo "Database '$TARGET_DB' initialized successfully."
fi