#!/bin/bash
set -e

# Make sure GPG dir exists
if [ -f /genex_data/gnupg ]; then
  echo "GPG directory already exists"
else
  mkdir -p /genex_data/gnupg
  gpg --update-trustdb
fi

# Restore the database if it does not already exist.
if [ -f /genex_data/db/genex.db ]; then
  echo "Database already exists, skipping restore"
else
  echo "No database found, restoring from replica if exists"
  litestream restore -v -if-replica-exists -o /genex_data/db/genex.db "${REPLICA_URL}"
fi

# Run migrations
/app/bin/migrate

# connect to my tailnet
/app/tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock &
/app/tailscale up --authkey=${TAILSCALE_AUTHKEY} --hostname=fly-app

# Import all gpg keys


# Run litestream with your app as the subprocess.
exec litestream replicate -exec "/app/bin/server"
