#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [ ! -f .env ]; then
  if ! command -v openssl >/dev/null 2>&1; then
    printf '%s\n' 'Se necesita OpenSSL para generar contrasenas aleatorias.' >&2
    exit 1
  fi
  printf 'POSTGRES_PASSWORD=%s\nREPLICATION_PASSWORD=%s\n' "$(openssl rand -hex 24)" "$(openssl rand -hex 24)" > .env
  chmod 600 .env
fi
docker compose up -d --wait
for file in 01_ddl.sql 02_seed.sql 02_triggers.sql 03_views.sql 04_materialized_views.sql 05_procedures.sql 10_plan_antes.sql 06_indexes.sql 11_plan_despues.sql 07_security.sql 08_pruebas_requerimientos.sql; do
  printf 'Ejecutando %s\n' "$file"
  docker compose exec -T postgres_primary psql -v ON_ERROR_STOP=1 -U postgres -d ecommerce < "01_BaseDatos/$file"
done
printf '%s\n' 'Instalacion SQL completa. Para verificar ejecutar bash scripts/verificar.sh'
