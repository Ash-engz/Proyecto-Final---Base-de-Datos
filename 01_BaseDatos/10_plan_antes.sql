-- REQUERIMIENTO 10: PLAN ANTES DEL INDICE ESPECIFICO
EXPLAIN (ANALYZE, BUFFERS)
SELECT o.order_id, o.ordered_at, o.customer_id,
       COALESCE(SUM(oi.quantity), 0) AS total_unidades,
       o.total_amount, o.status
FROM public.orders o
LEFT JOIN public.order_items oi ON oi.order_id = o.order_id
WHERE o.customer_id = 1
  AND o.ordered_at >= TIMESTAMP '2026-01-01'
  AND o.ordered_at < TIMESTAMP '2027-01-01'
GROUP BY o.order_id, o.ordered_at, o.customer_id, o.total_amount, o.status
ORDER BY o.ordered_at;
