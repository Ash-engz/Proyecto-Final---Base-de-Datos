#!/bin/bash
set -euo pipefail
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -v repl_password="$REPLICATION_PASSWORD" <<'SQL'
SELECT format('CREATE ROLE replicator WITH LOGIN REPLICATION PASSWORD %L', :'repl_password') \gexec
SQL
printf '%s\n' 'host replication replicator 0.0.0.0/0 scram-sha-256' >> "$PGDATA/pg_hba.conf"
printf '%s\n' 'host replication replicator ::/0 scram-sha-256' >> "$PGDATA/pg_hba.conf"
