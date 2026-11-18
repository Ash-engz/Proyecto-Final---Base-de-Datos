-- REQUERIMIENTO 11
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rol_ecommerce_lectura') THEN
        CREATE ROLE rol_ecommerce_lectura NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rol_ecommerce_operador') THEN
        CREATE ROLE rol_ecommerce_operador NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'db_admin') THEN
        CREATE ROLE db_admin LOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ecommerce_app') THEN
        CREATE ROLE ecommerce_app LOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'bi_analyst') THEN
        CREATE ROLE bi_analyst LOGIN;
    END IF;
END
$$;

REVOKE ALL ON DATABASE ecommerce FROM PUBLIC;
GRANT CONNECT ON DATABASE ecommerce TO db_admin, ecommerce_app, bi_analyst;
GRANT CONNECT ON DATABASE ecommerce TO rol_ecommerce_lectura, rol_ecommerce_operador;
GRANT ALL PRIVILEGES ON DATABASE ecommerce TO db_admin;
GRANT USAGE ON SCHEMA public TO ecommerce_app, bi_analyst, rol_ecommerce_lectura, rol_ecommerce_operador;
GRANT ALL ON SCHEMA public TO db_admin;
GRANT ALL ON ALL TABLES IN SCHEMA public TO db_admin;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO db_admin;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO db_admin;

REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;
GRANT SELECT ON public.vw_order_summary, public.vw_customer_summary, public.vw_inventory_status,
    public.mv_daily_sales, public.mv_product_performance TO bi_analyst, rol_ecommerce_lectura;

GRANT SELECT ON public.customers, public.addresses, public.products, public.inventory,
    public.orders, public.order_items, public.payments TO rol_ecommerce_operador;
GRANT INSERT ON public.orders, public.order_items, public.payments, public.order_status_history
    TO rol_ecommerce_operador;
GRANT UPDATE (status) ON public.orders TO rol_ecommerce_operador;
GRANT UPDATE (quantity_on_hand, updated_at) ON public.inventory TO rol_ecommerce_operador;
GRANT rol_ecommerce_operador TO ecommerce_app;

REVOKE EXECUTE ON PROCEDURE public.sp_registrar_venta(bigint,bigint,bigint,integer,character varying) FROM PUBLIC;
GRANT EXECUTE ON PROCEDURE public.sp_registrar_venta(bigint,bigint,bigint,integer,character varying)
    TO rol_ecommerce_operador;

ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;

SELECT rolname, rolcanlogin FROM pg_roles
WHERE rolname IN ('db_admin', 'ecommerce_app', 'bi_analyst', 'rol_ecommerce_operador', 'rol_ecommerce_lectura')
ORDER BY rolname;
