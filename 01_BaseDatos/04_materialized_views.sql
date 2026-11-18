
-- REQUERIMIENTO 7: CONSOLIDADO DIARIO DE VENTAS

DROP MATERIALIZED VIEW IF EXISTS public.mv_daily_sales;

CREATE MATERIALIZED VIEW public.mv_daily_sales AS

WITH unidades_por_pedido AS (
    SELECT
        order_id,
        SUM(quantity) AS unidades
    FROM public.order_items
    GROUP BY order_id
)

SELECT
    o.ordered_at::date AS fecha,
    COUNT(o.order_id) AS cantidad_pedidos,
    COUNT(DISTINCT o.customer_id)
        AS clientes_diferentes,
    COALESCE(SUM(u.unidades), 0)
        AS unidades_vendidas,
    ROUND(SUM(o.total_amount), 2)
        AS total_vendido,
    ROUND(AVG(o.total_amount), 2)
        AS ticket_promedio,
    MAX(o.total_amount)
        AS venta_mayor,
    MIN(o.total_amount)
        AS venta_menor

FROM public.orders o

LEFT JOIN unidades_por_pedido u
    ON o.order_id = u.order_id

GROUP BY o.ordered_at::date

WITH DATA;





-- ================================================
-- REQUERIMIENTO 8
-- RENDIMIENTO DE PRODUCTOS
-- VERSION DEFINITIVA
-- ================================================

DROP MATERIALIZED VIEW IF EXISTS public.mv_product_performance;

CREATE MATERIALIZED VIEW public.mv_product_performance AS

SELECT
    p.product_id AS id_producto,
    p.sku,
    p.name AS nombre_producto,
    c.name AS categoria_principal,

    COUNT(DISTINCT oi.order_id)
        AS cantidad_pedidos,

    COALESCE(SUM(oi.quantity), 0)
        AS unidades_vendidas,

    COALESCE(
        ROUND(SUM(oi.line_total), 2), 0
    ) AS ingresos_generados,

    COALESCE(
        ROUND(
            SUM(oi.quantity::numeric * p.cost_price), 2
        ), 0
    ) AS costo_total,

    COALESCE(
        ROUND(
            SUM(oi.line_total)
            - SUM(oi.quantity::numeric * p.cost_price), 2
        ), 0
    ) AS utilidad_estimada,

    ROUND(
        SUM(oi.line_total)
        / NULLIF(SUM(oi.quantity), 0), 2
    ) AS precio_promedio_venta,

    MAX(o.ordered_at)
        AS ultima_venta

FROM public.products p

LEFT JOIN public.product_categories pc
    ON p.product_id = pc.product_id
    AND pc.is_primary IS TRUE

LEFT JOIN public.categories c
    ON pc.category_id = c.category_id

LEFT JOIN public.order_items oi
    ON p.product_id = oi.product_id

LEFT JOIN public.orders o
    ON oi.order_id = o.order_id

GROUP BY
    p.product_id,
    p.sku,
    p.name,
    c.name

WITH DATA;
