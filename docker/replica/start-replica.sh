#!/bin/bash
set -euo pipefail
export PGDATA="${PGDATA:-/var/lib/postgresql/data/pgdata}"
if [ "$(id -u)" = 0 ]; then
  mkdir -p "$PGDATA"
  chown -R postgres:postgres /var/lib/postgresql/data
  chmod 700 "$PGDATA"
  exec gosu postgres bash "$0" "$@"
fi
export PGPASSFILE=/var/lib/postgresql/data/.pgpass
printf '%s\n' "${PRIMARY_HOST:-postgres_primary}:5432:replication:replicator:${REPLICATION_PASSWORD}" > "$PGPASSFILE"
chmod 600 "$PGPASSFILE"
if [ ! -f "$PGDATA/PG_VERSION" ]; then
  until pg_isready -h "${PRIMARY_HOST:-postgres_primary}" -p 5432 -U postgres; do
    sleep 2
  done
  pg_basebackup -h "${PRIMARY_HOST:-postgres_primary}" -p 5432 -U replicator -D "$PGDATA" -Fp -Xs -R -P
fi
exec docker-entrypoint.sh postgres -c hot_standby=on
