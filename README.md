# Proyecto Final - Base de Datos II

## Ejecucion automatica desde GitHub

Clonar este repositorio y ejecutar desde su raiz en una terminal Bash con Docker y Docker Compose V2 instalados:

```bash
git clone https://github.com/Ash-engz/Proyecto-Final---Base-de-Datos.git
cd Proyecto-Final---Base-de-Datos
bash scripts/instalar.sh
bash scripts/verificar.sh
```

El instalador crea un archivo `.env` privado con claves aleatorias, inicia las dos instancias PostgreSQL, espera a que esten saludables, ejecuta los SQL en el orden previsto y realiza las primeras comprobaciones. No ejecutar `instalar.sh` dos veces en los mismos volumenes: los scripts base estan disenados para instalarse en una base nueva. Si es necesario repetir la prueba, crear un entorno Docker aislado y limpio; no borrar datos del entorno del equipo.

Los servicios deben estar disponibles en `127.0.0.1:5440` (principal) y `127.0.0.1:5433` (replica). Si esos puertos ya estan ocupados, cambiar el puerto publicado en `docker-compose.yml` antes de iniciar.

El archivo `.env` no se versiona ni debe publicarse. El archivo `.env.example` muestra las variables requeridas.

Para realizar un respaldo actualizado:

```bash
bash scripts/backup.sh
```

**Limitaciones de la ejecucion automatica:** la comprobacion de presencia de un objeto SQL no sustituye sus pruebas funcionales (por ejemplo, una venta fallida y el rollback). El archivo `.pbix` requiere una instalacion compatible de Power BI Desktop para su inspeccion visual. No se han ejecutado contenedores en el entorno donde se preparo esta version, por lo que deben realizarse pruebas de integracion en Docker antes de la entrega final.

**Contenido historico:** las carpetas `Proyecto_Base_de_Datos_II_Marcos_Monzon/` y `Proyecto_Base_de_Datos_II_Ashly_Englenton/` corresponden a versiones previas. El agente debe ejecutar solo los scripts de la raiz, `scripts/` y `01_BaseDatos/`, que usan PostgreSQL.

Universidad Panamericana. PostgreSQL 16, Docker Compose, DBeaver y Power BI.

Participantes: Marcos Monzon y Ashly (completar apellido y ambos carnes antes de entregar).

## Arquitectura

Cliente SQL / DBeaver / Power BI -> PostgreSQL principal (localhost:5440) -> replicacion fisica WAL -> PostgreSQL replica (localhost:5433, solo lectura).

## Requisitos

Docker Desktop con Docker Compose V2, Power BI Desktop para abrir el archivo `.pbix`, DBeaver opcional. No se requiere PostgreSQL instalado localmente.

## Primer arranque

1. En esta misma carpeta, copiar `.env.example` a `.env` y cambiar las dos claves por contrasenas distintas, sin espacios, dos puntos ni simbolos especiales. No compartir `.env` ni subirlo a repositorios publicos.
2. Ejecutar `docker compose up -d`.
3. Ejecutar `docker compose ps` y esperar a que ambos contenedores esten en estado healthy.
4. Conectar DBeaver: tipo PostgreSQL, host `127.0.0.1`, puerto `5440`, base `ecommerce`, usuario `postgres`, clave indicada en `.env`.
5. Ejecutar cada script del listado siguiente en el orden indicado.

## Orden de scripts en una base nueva

1. `01_BaseDatos/01_ddl.sql`
2. `01_BaseDatos/02_seed.sql`
3. `01_BaseDatos/02_triggers.sql`
4. `01_BaseDatos/03_views.sql`
5. `01_BaseDatos/04_materialized_views.sql`
6. `01_BaseDatos/05_procedures.sql`
7. `01_BaseDatos/10_plan_antes.sql` y guardar su plan de ejecucion y tiempo.
8. `01_BaseDatos/06_indexes.sql`
9. `01_BaseDatos/11_plan_despues.sql` y comparar el plan y tiempo con el anterior.
10. `01_BaseDatos/07_security.sql`
11. `01_BaseDatos/08_pruebas_requerimientos.sql`

`04_validaciones_materialized_views.sql` es opcional: puede ejecutarse tras crear las vistas materializadas. La carga de datos semilla debe efectuarse ANTES de activar los triggers de venta, pues corresponde al estado historico de los pedidos, no a ventas nuevas.

## Usuarios para evaluacion

El script crea `db_admin`, `ecommerce_app` y `bi_analyst`, inicialmente sin contrasena para impedir accesos inseguros. Tras ejecutar la seguridad, iniciar una sesion SQL como postgres y asignar claves privadas utilizando sentencias `ALTER ROLE db_admin PASSWORD 'CLAVE_NUEVA';`, `ALTER ROLE ecommerce_app PASSWORD 'CLAVE_NUEVA';` y `ALTER ROLE bi_analyst PASSWORD 'CLAVE_NUEVA';`. No reutilizar las claves de ejemplo. El usuario `bi_analyst` solo debe consultar las vistas autorizadas.

## Verificacion de replicacion

En la conexion principal ejecutar `SELECT * FROM pg_stat_replication;` (debe aparecer una replica en estado `streaming`). En la conexion con puerto `5433`, ejecutar `SELECT pg_is_in_recovery();` (debe retornar `true`). Las operaciones INSERT/UPDATE/DELETE deben ejecutarse unicamente sobre la principal y consultarse desde la replica, preferiblemente con una tabla de prueba propia para evitar modificar datos del proyecto.

## Backup y restauracion

Ver el archivo `03_Backup/instrucciones_restore.txt`. Incluye el backup heredado de la version anterior. Generar un backup actualizado despues de todas las correcciones y probarlo en la base de prueba `ecommerce_restore`.

## Power BI

Abrir `04_PowerBI/dashboard.pbix`. Para la demostracion final se deben verificar las cinco metricas, cinco graficos y tres filtros del requerimiento 15, y cambiar la conexion al usuario `bi_analyst`. El PBIX entregado se conserva tal como fue proporcionado por el equipo: no se certifica el cumplimiento total del requisito 15.

## Detener infraestructura

Ejecutar `docker compose down` para detener sin borrar datos. No usar `docker compose down -v` sin un respaldo verificado: elimina los volumenes de la base y la replica.

## Consideraciones importantes

El archivo `.env` no forma parte del ZIP por seguridad. Debe crearse desde el ejemplo antes de iniciar. PostgreSQL replica se inicializa automaticamente mediante `pg_basebackup` al crear su volumen por primera vez; en arranques posteriores continua desde los datos persistidos.

La cuenta `db_admin` tiene privilegios administrativos dentro de la base y los objetos existentes. Para tareas de administracion global de PostgreSQL, se mantiene la cuenta `postgres`.

No se ha realizado una prueba de arranque real de Docker en el entorno de preparacion del ZIP. Antes de entregar al docente se requiere probar en Docker Desktop desde una carpeta nueva y capturar los resultados.
