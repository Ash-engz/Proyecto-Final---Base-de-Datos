# Proyecto Final - Base de Datos II

## Universidad Panamericana

**Proyecto:** Sistema de Base de Datos para E-Commerce  
**Motor de base de datos:** PostgreSQL 16  
**Infraestructura:** Docker y Docker Compose  
**Administración:** DBeaver  
**Análisis de datos:** Power BI  

**Integrantes:**
- Marcos Naasón Monzón Zacarias ID: 000149995
- Ashly Esther Englenton Zepeda ID: 000151177

---

## 1. Descripción del proyecto

El proyecto consiste en implementar una solución de base de datos para una empresa de comercio electrónico utilizando PostgreSQL.

La solución incorpora:

- Auditoría de cambios de precios.
- Control automático de inventario.
- Historial de estados de pedidos.
- Vistas para consultas comerciales.
- Vistas materializadas para análisis de ventas.
- Procedimientos almacenados y transacciones.
- Optimización mediante índices.
- Seguridad mediante usuarios y roles.
- Replicación entre dos instancias PostgreSQL.
- Respaldo y recuperación de información.
- Dashboard gerencial en Power BI.

El proyecto está preparado para ejecutarse mediante Docker y Docker Compose.

---

## 2. Requisitos previos

Para ejecutar el proyecto se necesita:

1. Git.
2. Docker Engine o Docker Desktop.
3. Docker Compose V2.
4. Bash.
5. OpenSSL.

Herramientas opcionales:

- DBeaver para administrar PostgreSQL.
- Power BI Desktop para visualizar el dashboard.

No es necesario instalar PostgreSQL directamente en el sistema operativo.

---

## 3. Clonar el repositorio

Ejecutar:

```bash
git clone https://github.com/Ash-engz/Proyecto-Final---Base-de-Datos.git
```

Ingresar al directorio:

```bash
cd Proyecto-Final---Base-de-Datos
```

---

## 4. Instalación automática

El proyecto incluye un script que configura el entorno y ejecuta los archivos SQL.

Ejecutar:

```bash
bash scripts/instalar.sh
```

El script realiza las siguientes operaciones:

1. Genera las variables de entorno necesarias.
2. Inicia PostgreSQL principal mediante Docker.
3. Inicia PostgreSQL réplica.
4. Espera a que los contenedores estén disponibles.
5. Crea las tablas de la base de datos.
6. Carga los datos iniciales.
7. Crea los triggers.
8. Crea las vistas.
9. Crea las vistas materializadas.
10. Crea los procedimientos almacenados.
11. Ejecuta las consultas de optimización.
12. Crea los índices.
13. Configura los usuarios y privilegios.
14. Ejecuta consultas iniciales de verificación.

**Importante:** la instalación debe ejecutarse sobre un entorno nuevo. No ejecutar nuevamente el instalador sobre una base de datos que ya tenga las tablas creadas.

---

## 5. Infraestructura Docker

El proyecto utiliza dos instancias PostgreSQL.

| Instancia | Puerto | Función |
|-----------|--------|---------|
| PostgreSQL principal | 5440 | Lectura y escritura |
| PostgreSQL réplica | 5433 | Lectura y replicación |

Ambas instancias se comunican mediante la red creada por Docker Compose.

### Iniciar los contenedores manualmente

Si las variables de entorno ya están configuradas:

```bash
docker compose up -d
```

### Verificar los contenedores

```bash
docker compose ps
```

Los contenedores deben aparecer activos y saludables.

### Detener la infraestructura

```bash
docker compose down
```

Este comando detiene los contenedores sin eliminar los volúmenes persistentes.

---

## 6. Configuración de variables de entorno

El repositorio contiene:

```text
.env.example
```

Si se realiza la instalación manual, copiarlo como:

```text
.env
```

Configurar las variables:

```text
POSTGRES_PASSWORD=CONTRASENA_SEGURA
REPLICATION_PASSWORD=OTRA_CONTRASENA_SEGURA
```

El archivo `.env` contiene información sensible y no debe publicarse en GitHub.

El instalador automático genera las credenciales cuando no existe dicho archivo.

---

## 7. Base de datos

**Nombre de la base de datos:**

```text
ecommerce
```

**Conexión principal:**

```text
Host: 127.0.0.1
Puerto: 5440
Base de datos: ecommerce
Usuario: postgres
```

La contraseña corresponde a `POSTGRES_PASSWORD`, definida en el archivo `.env`.

### Scripts SQL

Los archivos se encuentran en:

```text
01_BaseDatos/
```

Orden de ejecución:

1. `01_ddl.sql`
2. `02_seed.sql`
3. `02_triggers.sql`
4. `03_views.sql`
5. `04_materialized_views.sql`
6. `05_procedures.sql`
7. `10_plan_antes.sql`
8. `06_indexes.sql`
9. `11_plan_despues.sql`
10. `07_security.sql`
11. `08_pruebas_requerimientos.sql`

La instalación automática respeta este orden.

---

## 8. Requerimientos implementados

| Número | Requerimiento | Mecanismo |
|--------|---------------|-----------|
| 1 | Auditoría de cambios de precios | Trigger |
| 2 | Control automático de inventario | Trigger |
| 3 | Historial de estados de pedidos | Trigger |
| 4 | Resumen general de pedidos | View |
| 5 | Resumen de clientes | View |
| 6 | Estado de inventario | View |
| 7 | Consolidado diario de ventas | Materialized View |
| 8 | Rendimiento de productos | Materialized View |
| 9 | Registro transaccional de ventas | Stored Procedure |
| 10 | Optimización de consultas | Index y Execution Plan |
| 11 | Seguridad y control de acceso | Users, Roles y Privileges |
| 12 | Base de datos espejo | Replicación PostgreSQL |
| 13 | Respaldo completo | pg_dump |
| 14 | Recuperación de información | pg_restore |
| 15 | Dashboard gerencial | Power BI |

La existencia de los archivos no sustituye las pruebas funcionales correspondientes.

---

## 9. Verificación automática

Ejecutar:

```bash
bash scripts/verificar.sh
```

Este script comprueba:

- Estado de los contenedores.
- Existencia de clientes.
- Existencia de productos.
- Existencia de pedidos.
- Estado de replicación.
- Funcionamiento de las consultas de verificación.

Los resultados deben revisarse para confirmar que las operaciones se realizaron correctamente.

---

## 10. Verificación de replicación

La infraestructura utiliza replicación física de PostgreSQL.

### Comprobar el servidor principal

```bash
docker compose exec postgres_primary psql -U postgres -d ecommerce -c "SELECT state, sync_state FROM pg_stat_replication;"
```

Resultado esperado:

```text
state
---------
streaming
```

### Comprobar la instancia réplica

```bash
docker compose exec postgres_replica psql -U postgres -d ecommerce -c "SELECT pg_is_in_recovery();"
```

Resultado esperado:

```text
pg_is_in_recovery
----------------
t
```

La replicación debe verificarse adicionalmente mediante operaciones INSERT, UPDATE y DELETE realizadas sobre la instancia principal.

La réplica debe reflejar los cambios realizados.

---

## 11. Seguridad y privilegios

El sistema contempla tres perfiles principales:

### db_admin

Usuario destinado a tareas administrativas de la base de datos.

### ecommerce_app

Usuario utilizado para operaciones de la plataforma de comercio electrónico.

### bi_analyst

Usuario destinado a consultas analíticas.

Debe disponer de permisos de lectura sobre las vistas autorizadas, sin modificar directamente la información transaccional.

Las contraseñas de estos usuarios deben establecerse después de ejecutar el script de seguridad.

El proyecto utiliza el principio de mínimo privilegio.

---

## 12. Respaldo de la base de datos

Para generar un respaldo actualizado:

```bash
bash scripts/backup.sh
```

El respaldo se almacena en:

```text
03_Backup/backup_actual.dump
```

El repositorio también incluye un respaldo original del proyecto.

Las instrucciones de recuperación se encuentran en:

```text
03_Backup/instrucciones_restore.txt
```

---

## 13. Recuperación de información

La restauración debe ejecutarse en un ambiente controlado.

El procedimiento consiste en:

1. Generar un respaldo.
2. Registrar las cantidades de clientes, productos y pedidos.
3. Preparar una base de datos de prueba.
4. Simular una pérdida de información en esa base.
5. Comprobar la pérdida.
6. Restaurar la información.
7. Comparar las cantidades recuperadas.

La demostración no debe eliminar información de la base de datos principal.

---

## 14. Dashboard en Power BI

El archivo del dashboard se encuentra en:

```text
04_PowerBI/dashboard.pbix
```

El requerimiento contempla cinco indicadores:

1. Ventas totales.
2. Cantidad total de pedidos.
3. Ticket promedio.
4. Cantidad de clientes con compras.
5. Cantidad total de unidades vendidas.

También contempla las siguientes visualizaciones:

- Ventas por mes.
- Evolución de ventas.
- Ventas por categoría.
- Top 10 productos por monto vendido.
- Top 10 clientes por monto comprado.

Filtros requeridos:

- Rango de fechas.
- Categoría.
- Producto.

El archivo PBIX se conserva como parte del proyecto. Su cumplimiento completo debe verificarse en Power BI Desktop antes de la evaluación final.

---

## 15. Estructura del proyecto

```text
Proyecto-Final---Base-de-Datos/
|
|-- README.md
|-- README.pdf
|-- docker-compose.yml
|-- .env.example
|-- .gitignore
|
|-- docker/
|   |-- primary/
|   |-- replica/
|
|-- 01_BaseDatos/
|   |-- 01_ddl.sql
|   |-- 02_seed.sql
|   |-- 02_triggers.sql
|   |-- 03_views.sql
|   |-- 04_materialized_views.sql
|   |-- 05_procedures.sql
|   |-- 06_indexes.sql
|   |-- 07_security.sql
|   |-- 08_pruebas_requerimientos.sql
|   |-- 10_plan_antes.sql
|   |-- 11_plan_despues.sql
|
|-- 02_Replicacion/
|   |-- configuracion_replica.pdf
|
|-- 03_Backup/
|   |-- backup_original.dump
|   |-- instrucciones_restore.txt
|
|-- 04_PowerBI/
|   |-- dashboard.pbix
|
|-- scripts/
|   |-- instalar.sh
|   |-- verificar.sh
|   |-- backup.sh
```

---

## 16. Consideraciones para la evaluación automática

El proyecto está organizado para facilitar su ejecución mediante un agente de inteligencia artificial con acceso a Git, Docker y una terminal compatible.

El agente deberá:

1. Clonar el repositorio.
2. Leer este README.
3. Comprobar los requisitos previos.
4. Ejecutar el instalador.
5. Verificar las dos instancias PostgreSQL.
6. Ejecutar las pruebas disponibles.
7. Comprobar el funcionamiento de los requerimientos.
8. Generar y verificar un respaldo.
9. Ejecutar una restauración controlada.
10. Documentar los resultados obtenidos.

**Estado de validación:** los archivos fueron organizados y revisados estáticamente. La instalación completa debe probarse en un ambiente Docker limpio antes de afirmar que todos los requerimientos funcionan correctamente.

---

## 17. Autores

**Universidad Panamericana**

Proyecto Final de Base de Datos II

**Integrantes:**

- Marcos Monzón
- Ashly Englenton

**Tecnologías utilizadas:**

PostgreSQL 16, Docker, Docker Compose, SQL, DBeaver y Power BI.
