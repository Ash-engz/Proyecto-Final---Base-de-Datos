-- VERIFICACION DE REQUERIMIENTOS 1 A 11
SELECT COUNT(*) AS total_clientes FROM public.customers;
SELECT COUNT(*) AS total_productos FROM public.products;
SELECT COUNT(*) AS total_pedidos FROM public.orders;
SELECT COUNT(*) AS auditorias FROM public.price_audit;
SELECT COUNT(*) AS cambios_estado FROM public.order_status_history;
SELECT COUNT(*) AS resumen_pedidos FROM public.vw_order_summary;
SELECT COUNT(*) AS resumen_clientes FROM public.vw_customer_summary;
SELECT COUNT(*) AS filas_inventario FROM public.vw_inventory_status;
SELECT estado_inventario, COUNT(*) FROM public.vw_inventory_status GROUP BY estado_inventario;
SELECT COUNT(*) AS dias_con_ventas FROM public.mv_daily_sales;
SELECT COUNT(*) AS rendimiento_productos FROM public.mv_product_performance;
SELECT indexname FROM pg_indexes WHERE tablename = 'orders' ORDER BY indexname;
SELECT has_function_privilege('ecommerce_app', 'public.sp_registrar_venta(bigint,bigint,bigint,integer,character varying)', 'EXECUTE') AS app_ejecuta_ventas;
SELECT has_table_privilege('bi_analyst', 'public.orders', 'UPDATE') AS analista_modifica_pedidos;
SELECT has_table_privilege('bi_analyst', 'public.mv_daily_sales', 'SELECT') AS analista_lee_ventas;
