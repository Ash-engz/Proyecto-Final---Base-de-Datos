#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
docker compose ps
docker compose exec -T postgres_primary psql -v ON_ERROR_STOP=1 -U postgres -d ecommerce -c "SELECT count(*) AS clientes FROM public.customers"
docker compose exec -T postgres_primary psql -v ON_ERROR_STOP=1 -U postgres -d ecommerce -c "SELECT count(*) AS productos FROM public.products"
docker compose exec -T postgres_primary psql -v ON_ERROR_STOP=1 -U postgres -d ecommerce -c "SELECT count(*) AS pedidos FROM public.orders"
docker compose exec -T postgres_primary psql -v ON_ERROR_STOP=1 -U postgres -d ecommerce -c "SELECT state, sync_state FROM pg_stat_replication"
docker compose exec -T postgres_replica psql -v ON_ERROR_STOP=1 -U postgres -d ecommerce -c "SELECT pg_is_in_recovery() AS es_replica"
docker compose exec -T postgres_primary psql -v ON_ERROR_STOP=1 -U postgres -d ecommerce < 01_BaseDatos/08_pruebas_requerimientos.sql
