

-- REQUERIMIENTO 4: RESUMEN GENERAL DE PEDIDOS

CREATE OR REPLACE VIEW public.vw_order_summary AS

WITH detalle_pedidos AS (
    SELECT
        order_id,
        COUNT(DISTINCT product_id) AS productos_diferentes,
        SUM(quantity) AS total_unidades
    FROM public.order_items
    GROUP BY order_id
),

estado_pagos AS (
    SELECT
        order_id,
        STRING_AGG(
            DISTINCT status,
            ', ' ORDER BY status
        ) AS estado_pago
    FROM public.payments
    GROUP BY order_id
)

SELECT
    o.order_id AS id_pedido,
    o.ordered_at AS fecha_pedido,
    c.customer_id AS id_cliente,
    CONCAT_WS(' ', c.first_name, c.last_name)
        AS nombre_completo,
    COALESCE(d.productos_diferentes, 0)
        AS productos_diferentes,
    COALESCE(d.total_unidades, 0)
        AS total_unidades,
    o.subtotal,
    o.total_amount AS total_pedido,
    o.status AS estado_pedido,
    COALESCE(p.estado_pago, 'SIN PAGO')
        AS estado_pago

FROM public.orders o

INNER JOIN public.customers c
    ON o.customer_id = c.customer_id

LEFT JOIN detalle_pedidos d
    ON o.order_id = d.order_id

LEFT JOIN estado_pagos p
    ON o.order_id = p.order_id;





-- REQUERIMIENTO 5
-- RESUMEN DE COMPORTAMIENTO DE CLIENTES


CREATE OR REPLACE VIEW public.vw_customer_summary AS

WITH unidades_por_pedido AS (
    SELECT
        order_id,
        SUM(quantity) AS total_unidades
    FROM public.order_items
    GROUP BY order_id
),

resumen_cliente AS (
    SELECT
        o.customer_id,
        COUNT(o.order_id) AS total_pedidos,
        COALESCE(SUM(u.total_unidades), 0)
            AS total_productos_comprados,
        COALESCE(SUM(o.total_amount), 0)
            AS monto_historico,
        COALESCE(AVG(o.total_amount), 0)
            AS ticket_promedio,
        MIN(o.ordered_at) AS primera_compra,
        MAX(o.ordered_at) AS ultima_compra
    FROM public.orders o
    LEFT JOIN unidades_por_pedido u
        ON o.order_id = u.order_id
    GROUP BY o.customer_id
)

SELECT
    c.customer_id AS id_cliente,
    CONCAT_WS(' ', c.first_name, c.last_name)
        AS nombre_completo,
    COALESCE(r.total_pedidos, 0)
        AS total_pedidos,
    COALESCE(r.total_productos_comprados, 0)
        AS total_productos_comprados,
    COALESCE(r.monto_historico, 0)
        AS monto_historico,
    ROUND(COALESCE(r.ticket_promedio, 0), 2)
        AS ticket_promedio,
    r.primera_compra,
    r.ultima_compra
FROM public.customers c
LEFT JOIN resumen_cliente r
    ON c.customer_id = r.customer_id;





-- REQUERIMIENTO 6
-- VISTA DEL ESTADO DE INVENTARIO


CREATE OR REPLACE VIEW public.vw_inventory_status AS

SELECT
    i.warehouse_id AS id_almacen,
    w.name AS nombre_almacen,
    w.city AS ciudad,
    i.product_id AS id_producto,
    p.sku,
    p.name AS nombre_producto,
    COALESCE(c.name, 'SIN CATEGORIA') AS categoria,
    p.unit_price AS precio,

    i.quantity_on_hand AS existencia_actual,
    i.quantity_reserved AS cantidad_reservada,

    (i.quantity_on_hand - i.quantity_reserved)
        AS existencia_disponible,

    i.reorder_point AS punto_reorden,

    p.unit_price AS costo_unitario,

    ROUND(
        (i.quantity_on_hand - i.quantity_reserved)
        * p.unit_price, 2
    ) AS valor_inventario,

    CASE
        WHEN (i.quantity_on_hand - i.quantity_reserved) <= 0
            THEN 'SIN STOCK'

        WHEN (i.quantity_on_hand - i.quantity_reserved)
             <= 10
            THEN 'STOCK BAJO'

        ELSE 'STOCK NORMAL'
    END AS estado_inventario

FROM public.inventory i

INNER JOIN public.products p
    ON i.product_id = p.product_id

INNER JOIN public.warehouses w
    ON i.warehouse_id = w.warehouse_id

LEFT JOIN public.product_categories pc
    ON i.product_id = pc.product_id AND pc.is_primary = TRUE

LEFT JOIN public.categories c
    ON pc.category_id = c.category_id;
