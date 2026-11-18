-- REQUERIMIENTO 10: OPTIMIZACION DE INDICES


-- 1. Indice para productos en carritos
CREATE INDEX IF NOT EXISTS idx_cart_items_product
ON public.cart_items (product_id);

-- 2. Indice para categorias jerarquicas
CREATE INDEX IF NOT EXISTS idx_categories_parent
ON public.categories (parent_category_id);

-- 3. Indice para cupones aplicados
CREATE INDEX IF NOT EXISTS idx_order_coupons_coupon
ON public.order_coupons (coupon_id);

-- 4. Indice para detalles por pedido
CREATE INDEX IF NOT EXISTS idx_order_items_order
ON public.order_items (order_id);

-- 5. Indice para pedidos por cliente
CREATE INDEX IF NOT EXISTS idx_orders_customer
ON public.orders (customer_id);

-- 6. Indice para direcciones de envio
CREATE INDEX IF NOT EXISTS idx_orders_shipping_address
ON public.orders (shipping_address_id);

-- 7. Indice para historial de pedidos
CREATE INDEX IF NOT EXISTS idx_order_status_history_order
ON public.order_status_history (order_id);

-- 8. Indice para productos por categoria
CREATE INDEX IF NOT EXISTS idx_product_categories_category
ON public.product_categories (category_id);

-- 9. Indice para envios por almacen
CREATE INDEX IF NOT EXISTS idx_shipments_warehouse
ON public.shipments (warehouse_id);
CREATE INDEX IF NOT EXISTS idx_orders_customer_date
ON public.orders(customer_id, ordered_at);
