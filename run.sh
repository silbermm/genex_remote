#!/bin/bash
set -e

# connect to my tailnet
/app/tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock &
echo "bringing up tailscale"
/app/tailscale up --authkey=${TAILSCALE_AUTHKEY} --hostname=genex-remote-service
echo "done $?"

echo "100.100.20.30    silverstore.tail6c78e.ts.net" >> /etc/hosts

# Make sure GPG dir exists
if [ -f /genex_data/gnupg ]; then
  echo "GPG directory already exists"
else
  mkdir -p /genex_data/gnupg
  gpg --update-trustdb
fi

# Restore the database if it does not already exist.
if [ -f /sql_data/genex.db ]; then
  echo "Database already exists, skipping restore"
else
  echo "No database found, restoring from replica if exists"
  litestream restore -v -if-replica-exists /sql_data/genex.db
fi

# Run migrations
/app/bin/migrate

# Import all gpg keys

# Run litestream with your app as the subprocess.
exec litestream replicate -exec "/app/bin/server"
