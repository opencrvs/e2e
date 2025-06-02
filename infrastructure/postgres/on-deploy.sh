#!/bin/bash
set -e

# Configuration
: "${POSTGRES_HOST:=postgres}"
: "${POSTGRES_PORT:=5432}"
: "${POSTGRES_USER:=postgres}"
: "${POSTGRES_PASSWORD:=postgres}"
: "${TARGET_DB:=events}"
: "${EVENTS_MIGRATOR_POSTGRES_PASSWORD:?Must set EVENTS_MIGRATOR_POSTGRES_PASSWORD}"
: "${EVENTS_APP_POSTGRES_PASSWORD:?Must set EVENTS_APP_POSTGRES_PASSWORD}"

# Install required tools
apt-get update && apt-get install -y postgresql-client curl

# Wait for PostgreSQL to be ready
curl -L https://github.com/ufoscout/docker-compose-wait/releases/download/2.9.0/wait --output /wait
chmod +x /wait
/wait

# Check if database exists
echo "Checking if database '$TARGET_DB' exists..."
DB_EXISTS=$(PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname = '$TARGET_DB';")

if [[ "$DB_EXISTS" == "1" ]]; then
  echo "Database '$TARGET_DB' already exists. Skipping init."
else
  echo "Database '$TARGET_DB' does not exist. Initializing..."

  PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d postgres <<EOF
CREATE DATABASE events;

CREATE ROLE events_migrator WITH LOGIN PASSWORD '${EVENTS_MIGRATOR_POSTGRES_PASSWORD}';
CREATE ROLE events_app WITH LOGIN PASSWORD '${EVENTS_APP_POSTGRES_PASSWORD}';

GRANT CONNECT ON DATABASE events TO events_migrator, events_app;
EOF

  PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d events <<EOF
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
REVOKE CREATE ON SCHEMA public FROM events_migrator;

CREATE SCHEMA app AUTHORIZATION events_migrator;

ALTER ROLE events_migrator SET search_path = app;
ALTER ROLE events_app SET search_path = app;
EOF

  echo "Database '$TARGET_DB' initialized successfully."
fi