# Configuracion de la replica PostgreSQL

Version: PostgreSQL 16, imagen oficial `postgres:16`.

La instancia principal expone `127.0.0.1:5440` y la replica `127.0.0.1:5433`. Cada instancia dispone de un volumen persistente independiente. El arranque utiliza `docker-compose.yml`, `.env`, los scripts `docker/primary/init-replication.sh` y `docker/replica/start-replica.sh`.

El servidor principal activa `wal_level=replica`, `max_wal_senders=10` y `max_replication_slots=10`. El script de inicializacion crea un usuario de replicacion y permite su conexion autenticada. En el primer arranque la replica ejecuta `pg_basebackup -R` para copiar el cluster y configurar `standby.signal` y `primary_conninfo`. A continuacion se inicia en modo de recuperacion de solo lectura.

Comandos: `docker compose up -d`, `docker compose ps`, `docker compose exec postgres_primary psql -U postgres -d ecommerce -c "SELECT application_name,state,sync_state FROM pg_stat_replication"` y `docker compose exec postgres_replica psql -U postgres -d ecommerce -c "SELECT pg_is_in_recovery()"`.

Para evidenciar INSERT, UPDATE y DELETE se debe crear una tabla de prueba sobre el principal y consultar sus cambios desde el replica. Si la conexion no esta disponible, esperar unos segundos y verificar `docker compose logs postgres_replica`.

Capturas de evidencia de ejecucion real: pendientes. Este documento describe el procedimiento, pero las capturas deben tomarse de los contenedores Docker Desktop en la computadora del equipo.
