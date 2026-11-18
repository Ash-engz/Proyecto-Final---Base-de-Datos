#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

sql() {
  docker compose exec -T postgres_primary psql -X -v ON_ERROR_STOP=1 -U postgres -d ecommerce "$@"
}

echo 'INICIO DE VALIDACION INTEGRAL'

sql <<'SQL'
BEGIN;
DO $test$
DECLARE
    v_id BIGINT;
    v_price NUMERIC;
    v_count BIGINT;
    v_order BIGINT;
    v_status TEXT;
    v_hist BIGINT;
    v_customer BIGINT;
    v_address BIGINT;
    v_stock INTEGER;
    v_new_order BIGINT;
    v_total BIGINT;
    v_paid BIGINT;
    v_failed BOOLEAN := FALSE;
BEGIN
    SELECT product_id, unit_price INTO STRICT v_id, v_price FROM public.products ORDER BY product_id LIMIT 1 FOR UPDATE;
    SELECT count(*) INTO v_count FROM public.price_audit WHERE product_id = v_id;
    UPDATE public.products SET unit_price = v_price + 1 WHERE product_id = v_id;
    IF (SELECT count(*) FROM public.price_audit WHERE product_id = v_id AND old_price = v_price AND new_price = v_price + 1) < 1 OR
       (SELECT count(*) FROM public.price_audit WHERE product_id = v_id) <> v_count + 1 THEN
        RAISE EXCEPTION 'R1: auditoria no registra correctamente';
    END IF;
    UPDATE public.products SET unit_price = v_price + 1 WHERE product_id = v_id;
    IF (SELECT count(*) FROM public.price_audit WHERE product_id = v_id) <> v_count + 1 THEN
        RAISE EXCEPTION 'R1: auditoria duplicada sin cambio';
    END IF;
    RAISE NOTICE 'APROBADO R1: auditoria de precios';

    SELECT order_id, status INTO STRICT v_order, v_status FROM public.orders WHERE status = 'PENDING' ORDER BY order_id LIMIT 1 FOR UPDATE;
    SELECT count(*) INTO v_hist FROM public.order_status_history WHERE order_id = v_order;
    UPDATE public.orders SET status = 'PAID' WHERE order_id = v_order;
    IF NOT EXISTS (SELECT 1 FROM public.order_status_history WHERE order_id = v_order AND old_status = v_status AND new_status = 'PAID') OR
       (SELECT count(*) FROM public.order_status_history WHERE order_id = v_order) <> v_hist + 1 THEN
        RAISE EXCEPTION 'R3: historial incorrecto';
    END IF;
    UPDATE public.orders SET status = 'PAID' WHERE order_id = v_order;
    IF (SELECT count(*) FROM public.order_status_history WHERE order_id = v_order) <> v_hist + 1 THEN
        RAISE EXCEPTION 'R3: historial duplicado sin cambio';
    END IF;
    RAISE NOTICE 'APROBADO R3: historial de estados';

    IF EXISTS (
        SELECT 1 FROM public.vw_order_summary
        WHERE id_pedido IS NULL OR fecha_pedido IS NULL OR id_cliente IS NULL OR nombre_completo IS NULL
    ) OR (SELECT count(*) FROM public.vw_order_summary) <> (SELECT count(*) FROM public.orders) THEN
        RAISE EXCEPTION 'R4: resumen de pedidos incompleto';
    END IF;
    RAISE NOTICE 'APROBADO R4: resumen de pedidos';

    IF (SELECT count(*) FROM public.vw_customer_summary) <> (SELECT count(*) FROM public.customers) THEN
        RAISE EXCEPTION 'R5: resumen no incluye todos los clientes';
    END IF;
    RAISE NOTICE 'APROBADO R5: resumen de clientes';

    IF EXISTS (
        SELECT 1 FROM public.vw_inventory_status
        WHERE valor_inventario <> round(precio * existencia_disponible, 2)
           OR estado_inventario <> CASE WHEN existencia_disponible = 0 THEN 'SIN STOCK'
               WHEN existencia_disponible BETWEEN 1 AND 10 THEN 'STOCK BAJO' ELSE 'STOCK NORMAL' END
    ) OR (SELECT count(*) FROM public.vw_inventory_status) = 0 THEN
        RAISE EXCEPTION 'R6: calculo de inventario incorrecto';
    END IF;
    RAISE NOTICE 'APROBADO R6: vista de inventario';

    IF (SELECT count(*) FROM public.mv_daily_sales) = 0 OR
       EXISTS (SELECT 1 FROM public.mv_daily_sales WHERE cantidad_pedidos < 1 OR total_vendido IS NULL) THEN
        RAISE EXCEPTION 'R7: consolidado diario incorrecto';
    END IF;
    RAISE NOTICE 'APROBADO R7: consolidado diario';

    IF (SELECT count(*) FROM public.mv_product_performance) <> (SELECT count(*) FROM public.products) OR
       EXISTS (SELECT 1 FROM public.mv_product_performance WHERE unidades_vendidas < 0 OR ingresos_generados < 0) THEN
        RAISE EXCEPTION 'R8: rendimiento de productos incorrecto';
    END IF;
    RAISE NOTICE 'APROBADO R8: rendimiento de productos';

    SELECT a.customer_id, a.address_id, i.product_id, i.quantity_on_hand - i.quantity_reserved
      INTO v_customer, v_address, v_id, v_stock
      FROM public.addresses a CROSS JOIN public.inventory i
     WHERE i.warehouse_id = 1 AND i.quantity_on_hand - i.quantity_reserved >= 2
     ORDER BY a.address_id, i.product_id LIMIT 1;
    IF v_id IS NULL THEN
        RAISE EXCEPTION 'R2/R9: faltan datos de prueba para la venta';
    END IF;
    SELECT count(*) INTO v_total FROM public.orders;
    CALL public.sp_registrar_venta(v_customer, v_address, v_id, 1, 'CARD');
    IF (SELECT count(*) FROM public.orders) <> v_total + 1 THEN
        RAISE EXCEPTION 'R9: no se creo el pedido';
    END IF;
    SELECT max(order_id) INTO v_new_order FROM public.orders WHERE customer_id = v_customer;
    IF (SELECT count(*) FROM public.order_items WHERE order_id = v_new_order AND product_id = v_id AND quantity = 1) <> 1 OR
       (SELECT count(*) FROM public.payments WHERE order_id = v_new_order AND status = 'APPROVED') <> 1 OR
       (SELECT quantity_on_hand - quantity_reserved FROM public.inventory WHERE warehouse_id = 1 AND product_id = v_id) <> v_stock - 1 THEN
        RAISE EXCEPTION 'R2/R9: venta, pago o descuento de stock incorrecto';
    END IF;
    RAISE NOTICE 'APROBADO R2: trigger descuenta inventario';
    RAISE NOTICE 'APROBADO R9: procedimiento de venta completa';

    BEGIN
        CALL public.sp_registrar_venta(v_customer, v_address, v_id, v_stock + 100000, 'CARD');
    EXCEPTION WHEN OTHERS THEN
        v_failed := TRUE;
    END;
    IF NOT v_failed OR (SELECT count(*) FROM public.orders) <> v_total + 1 OR
       (SELECT quantity_on_hand - quantity_reserved FROM public.inventory WHERE warehouse_id = 1 AND product_id = v_id) <> v_stock - 1 THEN
        RAISE EXCEPTION 'R2/R9: venta sin stock no se revirtio';
    END IF;
    RAISE NOTICE 'APROBADO R2/R9: rechazo sin operaciones parciales';

    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname='public' AND tablename='orders' AND indexname='idx_orders_customer_date') THEN
        RAISE EXCEPTION 'R10: indice de busqueda por cliente/fecha ausente';
    END IF;
    RAISE NOTICE 'APROBADO R10: indice definido; revisar planes documentados';

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='db_admin' AND rolcanlogin) OR
       NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='ecommerce_app' AND rolcanlogin AND NOT rolsuper) OR
       NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='bi_analyst' AND rolcanlogin AND NOT rolsuper) OR
       has_table_privilege('bi_analyst','public.orders','UPDATE') OR
       NOT has_table_privilege('bi_analyst','public.mv_daily_sales','SELECT') OR
       NOT has_function_privilege('ecommerce_app','public.sp_registrar_venta(bigint,bigint,bigint,integer,character varying)','EXECUTE') THEN
        RAISE EXCEPTION 'R11: roles o privilegios incorrectos';
    END IF;
    RAISE NOTICE 'APROBADO R11: perfiles y privilegios basicos';
END
$test$;
ROLLBACK;
SQL

replication_status="$(sql -Atc "SELECT state FROM pg_stat_replication WHERE state = 'streaming' LIMIT 1")"
if [[ "$replication_status" != 'streaming' ]]; then
  echo 'ERROR R12: no hay replicacion streaming' >&2
  exit 1
fi
echo 'APROBADO R12: replicacion streaming'
docker compose exec -T postgres_replica psql -X -v ON_ERROR_STOP=1 -U postgres -d ecommerce -Atc "SELECT CASE WHEN pg_is_in_recovery() THEN 'APROBADO R12: replica de lectura' ELSE 'ERROR R12' END" | grep -q 'APROBADO R12'
sql -c 'CREATE TABLE public.prueba_replicacion_ci (id INTEGER PRIMARY KEY, valor INTEGER NOT NULL)'
sql -c 'INSERT INTO public.prueba_replicacion_ci VALUES (1, 10)'
replica_value=""
for i in {1..20}; do
  replica_value="$(docker compose exec -T postgres_replica psql -X -v ON_ERROR_STOP=1 -U postgres -d ecommerce -Atc "SELECT CASE WHEN to_regclass('public.prueba_replicacion_ci') IS NOT NULL THEN (SELECT valor FROM public.prueba_replicacion_ci WHERE id = 1)::text ELSE '' END" 2>/dev/null || true)"
  [[ "$replica_value" == '10' ]] && break
  sleep 0.2
done
[[ "$replica_value" == '10' ]] || { echo 'ERROR R12: INSERT no replicado' >&2; exit 1; }
sql -c 'UPDATE public.prueba_replicacion_ci SET valor = 20 WHERE id = 1'
for i in {1..20}; do
  replica_value="$(docker compose exec -T postgres_replica psql -X -v ON_ERROR_STOP=1 -U postgres -d ecommerce -Atc 'SELECT valor FROM public.prueba_replicacion_ci WHERE id = 1')"
  [[ "$replica_value" == '20' ]] && break
  sleep 0.2
done
[[ "$replica_value" == '20' ]] || { echo 'ERROR R12: UPDATE no replicado' >&2; exit 1; }
sql -c 'DELETE FROM public.prueba_replicacion_ci WHERE id = 1'
for i in {1..20}; do
  replica_value="$(docker compose exec -T postgres_replica psql -X -v ON_ERROR_STOP=1 -U postgres -d ecommerce -Atc 'SELECT count(*) FROM public.prueba_replicacion_ci WHERE id = 1')"
  [[ "$replica_value" == '0' ]] && break
  sleep 0.2
done
[[ "$replica_value" == '0' ]] || { echo 'ERROR R12: DELETE no replicado' >&2; exit 1; }
sql -c 'DROP TABLE public.prueba_replicacion_ci'
echo 'APROBADO R12: INSERT, UPDATE y DELETE replicados'

dump_file="$(mktemp)"
trap 'rm -f "$dump_file"' EXIT
docker compose exec -T postgres_primary pg_dump -U postgres -Fc ecommerce > "$dump_file"
docker compose exec -T postgres_primary pg_restore -l < "$dump_file" > /dev/null
echo 'APROBADO R13: backup generado y catalogo comprobado'

restore_db="ecommerce_prueba_restore"
docker compose exec -T postgres_primary dropdb -U postgres --if-exists "$restore_db"
docker compose exec -T postgres_primary createdb -U postgres "$restore_db"
docker compose exec -T postgres_primary pg_restore -U postgres --no-owner --no-acl -d "$restore_db" < "$dump_file"
original_counts="$(sql -Atc 'SELECT (SELECT count(*) FROM public.customers)::text || chr(44) || (SELECT count(*) FROM public.products)::text || chr(44) || (SELECT count(*) FROM public.orders)::text')"
restored_counts="$(docker compose exec -T postgres_primary psql -U postgres -d "$restore_db" -Atc 'SELECT (SELECT count(*) FROM public.customers)::text || chr(44) || (SELECT count(*) FROM public.products)::text || chr(44) || (SELECT count(*) FROM public.orders)::text')"
if [[ "$original_counts" != "$restored_counts" ]]; then
  echo "ERROR R14: conteos distintos $original_counts / $restored_counts" >&2
  exit 1
fi
docker compose exec -T postgres_primary psql -v ON_ERROR_STOP=1 -U postgres -d "$restore_db" -c 'TRUNCATE public.customers CASCADE' > /dev/null
docker compose exec -T postgres_primary dropdb -U postgres "$restore_db"
docker compose exec -T postgres_primary createdb -U postgres "$restore_db"
docker compose exec -T postgres_primary pg_restore -U postgres --no-owner --no-acl -d "$restore_db" < "$dump_file"
restored_counts="$(docker compose exec -T postgres_primary psql -U postgres -d "$restore_db" -Atc 'SELECT (SELECT count(*) FROM public.customers)::text || chr(44) || (SELECT count(*) FROM public.products)::text || chr(44) || (SELECT count(*) FROM public.orders)::text')"
if [[ "$original_counts" != "$restored_counts" ]]; then
  echo 'ERROR R14: la recuperacion fallo' >&2
  exit 1
fi
docker compose exec -T postgres_primary dropdb -U postgres "$restore_db"
echo 'APROBADO R14: perdida simulada y recuperacion aislada'

if [[ ! -s 04_PowerBI/dashboard.pbix ]]; then
  echo 'ERROR R15: archivo dashboard.pbix ausente o vacio' >&2
  exit 1
fi
echo 'PARCIAL R15: PBIX presente; indicadores, visualizaciones y conexion requieren inspeccion en Power BI Desktop'
echo 'FIN DE VALIDACION INTEGRAL'
