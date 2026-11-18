

-- VALIDACIONES DE VISTAS MATERIALIZADAS


-- =====================================================
-- REQUERIMIENTO 7: mv_daily_sales
-- =====================================================

-- 1. Verificar existencia de la vista materializada

SELECT
    schemaname AS esquema,
    matviewname AS vista_materializada,
    ispopulated AS contiene_datos
FROM pg_matviews
WHERE schemaname = 'public'
  AND matviewname = 'mv_daily_sales';


-- 2. Consultar las primeras 10 fechas de ventas

SELECT *
FROM public.mv_daily_sales
ORDER BY fecha
LIMIT 10;


-- 3. Verificar los resultados del 1 de mayo de 2026

SELECT
    fecha,
    cantidad_pedidos,
    clientes_diferentes,
    unidades_vendidas,
    total_vendido,
    ticket_promedio,
    venta_mayor,
    venta_menor
FROM public.mv_daily_sales
WHERE fecha = DATE '2026-05-01';


-- 4. Actualizar la vista materializada
-- Ejecutar esta sentencia cuando se requiera actualizar

REFRESH MATERIALIZED VIEW public.mv_daily_sales;


-- 5. Verificar cantidad de registros

SELECT COUNT(*) AS total_dias
FROM public.mv_daily_sales;



-- =====================================================
-- REQUERIMIENTO 8: mv_product_performance
-- =====================================================

-- 6. Verificar existencia de la vista materializada

SELECT
    schemaname AS esquema,
    matviewname AS vista_materializada,
    ispopulated AS contiene_datos
FROM pg_matviews
WHERE schemaname = 'public'
  AND matviewname = 'mv_product_performance';


-- 7. Consultar los 10 productos con mas unidades

SELECT
    id_producto,
    sku,
    nombre_producto,
    cantidad_pedidos,
    unidades_vendidas,
    ingresos_generados,
    costo_total,
    utilidad_estimada
FROM public.mv_product_performance
ORDER BY unidades_vendidas DESC, id_producto
LIMIT 10;


-- 8. Verificar utilidad estimada de todos los productos

SELECT
    COUNT(*) AS total_productos,

    COUNT(*) FILTER (
        WHERE utilidad_estimada =
              ingresos_generados - costo_total
    ) AS productos_correctos,

    COUNT(*) FILTER (
        WHERE utilidad_estimada IS DISTINCT FROM
              ingresos_generados - costo_total
    ) AS productos_con_diferencias

FROM public.mv_product_performance;


-- 9. Actualizar la segunda vista materializada
-- Ejecutar esta sentencia cuando se requiera actualizar

REFRESH MATERIALIZED VIEW public.mv_product_performance;


-- 10. Verificar cantidad de productos

SELECT COUNT(*) AS total_productos
FROM public.mv_product_performance;



-- =====================================================
-- VERIFICACION FINAL 
-- =====================================================

-- 11. Verificar ambas vistas materializadas

SELECT
    schemaname AS esquema,
    matviewname AS vista_materializada,
    ispopulated AS contiene_datos
FROM pg_matviews
WHERE schemaname = 'public'
  AND matviewname IN (
      'mv_daily_sales',
      'mv_product_performance'
  )
ORDER BY matviewname;


-- 12. Verificar cantidad de registros

SELECT
    'mv_daily_sales' AS vista_materializada,
    COUNT(*) AS total_registros
FROM public.mv_daily_sales

UNION ALL

SELECT
    'mv_product_performance',
    COUNT(*)
FROM public.mv_product_performance;
