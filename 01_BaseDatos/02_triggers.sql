
-- REQUERIMIENTO 1
-- AUDITORIA DE CAMBIOS DE PRECIOS

-- 1. Crear tabla para almacenar auditorias
CREATE TABLE IF NOT EXISTS public.price_audit (
    audit_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id BIGINT NOT NULL,
    old_price NUMERIC(12,2) NOT NULL,
    new_price NUMERIC(12,2) NOT NULL,
    changed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    changed_by TEXT NOT NULL
);

-- 2. Crear funcion de auditoria
CREATE OR REPLACE FUNCTION public.fn_price_audit()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.unit_price IS DISTINCT FROM NEW.unit_price THEN
        INSERT INTO public.price_audit (
            product_id,
            old_price,
            new_price,
            changed_at,
            changed_by
        )
        VALUES (
            NEW.product_id,
            OLD.unit_price,
            NEW.unit_price,
            CURRENT_TIMESTAMP,
            SESSION_USER
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Eliminar trigger anterior si existe
DROP TRIGGER IF EXISTS trg_price_audit
ON public.products;

-- 4. Crear trigger de auditoria
CREATE TRIGGER trg_price_audit
AFTER UPDATE OF unit_price
ON public.products
FOR EACH ROW
EXECUTE FUNCTION public.fn_price_audit();



-- REQUERIMIENTO 2
-- CONTROL AUTOMATICO DE INVENTARIO

CREATE OR REPLACE FUNCTION public.fn_inventory_sale()
RETURNS TRIGGER AS $$
BEGIN
    -- Descontar solamente si existe stock disponible.
    -- Se utiliza el almacen central (ID = 1).
    UPDATE public.inventory
    SET quantity_on_hand = quantity_on_hand - NEW.quantity,
        updated_at = CURRENT_TIMESTAMP
    WHERE warehouse_id = 1
      AND product_id = NEW.product_id
      AND quantity_on_hand - quantity_reserved >= NEW.quantity;

    -- Si no se actualizo ninguna fila,
    -- no existe inventario disponible suficiente.
    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Inventario insuficiente o inexistente para producto % en almacen 1. Cantidad solicitada: %',
            NEW.product_id, NEW.quantity;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_inventory_sale
ON public.order_items;

CREATE TRIGGER trg_inventory_sale
BEFORE INSERT
ON public.order_items
FOR EACH ROW
EXECUTE FUNCTION public.fn_inventory_sale();





-- REQUERIMIENTO 3
-- HISTORIAL DE ESTADOS DE PEDIDOS

-- 1. Crear tabla de historial
CREATE TABLE IF NOT EXISTS public.order_status_history (
    history_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id BIGINT NOT NULL,
    old_status VARCHAR(20) NOT NULL,
    new_status VARCHAR(20) NOT NULL,
    changed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    changed_by TEXT NOT NULL,
    CONSTRAINT fk_history_order
        FOREIGN KEY (order_id)
        REFERENCES public.orders(order_id)
        ON DELETE CASCADE
);

-- 2. Crear funcion de historial
CREATE OR REPLACE FUNCTION public.fn_order_status_history()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO public.order_status_history (
            order_id,
            old_status,
            new_status,
            changed_at,
            changed_by
        )
        VALUES (
            NEW.order_id,
            OLD.status,
            NEW.status,
            CURRENT_TIMESTAMP,
            SESSION_USER
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Eliminar trigger anterior si existe
DROP TRIGGER IF EXISTS trg_order_status_history
ON public.orders;

-- 4. Crear trigger
CREATE TRIGGER trg_order_status_history
AFTER UPDATE OF status
ON public.orders
FOR EACH ROW
EXECUTE FUNCTION public.fn_order_status_history();


