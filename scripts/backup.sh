#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
docker compose exec -T postgres_primary pg_dump -U postgres -Fc ecommerce > 03_Backup/backup_actual.dump
docker compose exec -T postgres_primary pg_restore -l < 03_Backup/backup_actual.dump > /dev/null
printf '%s\n' 'Backup generado y estructura comprobada en 03_Backup/backup_actual.dump'
