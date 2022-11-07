#!/bin/bash
set -e

# Restore the database if it does not already exist.
if [ -f /genex_data/db/genex.db ]; then
  echo "Database already exists, skipping restore"
else
  echo "No database found, restoring from replica if exists"
  litestream restore -v -if-replica-exists -o /genex_data/db/genex.db "${REPLICA_URL}"
fi

# Run migrations
/app/bin/migrate

# Run litestream with your app as the subprocess.
exec litestream replicate -exec "/app/bin/server"
