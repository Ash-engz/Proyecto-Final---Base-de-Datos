-- REQUERIMIENTO 9: REGISTRO TRANSACCIONAL DE VENTAS

CREATE OR REPLACE PROCEDURE public.sp_registrar_venta(
    IN p_cliente_id BIGINT,
    IN p_direccion_id BIGINT,
    IN p_producto_id BIGINT,
    IN p_cantidad INTEGER,
    IN p_metodo_pago VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_order_id BIGINT;
    v_precio NUMERIC;
    v_sku VARCHAR;
    v_producto VARCHAR;
    v_total NUMERIC;
    v_stock INTEGER;
    v_numero_pedido VARCHAR;
BEGIN

    -- 1. Validar cantidad solicitada
    IF p_cantidad IS NULL OR p_cantidad <= 0 THEN
        RAISE EXCEPTION
            'La cantidad debe ser mayor que cero';
    END IF;

    -- 2. Validar metodo de pago
    IF p_metodo_pago IS NULL
       OR p_metodo_pago NOT IN (
           'CARD',
           'TRANSFER',
           'WALLET',
           'CASH_ON_DELIVERY'
       ) THEN
        RAISE EXCEPTION
            'Metodo de pago no permitido';
    END IF;

    -- 3. Validar cliente y direccion
    PERFORM 1
    FROM public.addresses a
    WHERE a.address_id = p_direccion_id
      AND a.customer_id = p_cliente_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Cliente o direccion no validos';
    END IF;

    -- 4. Obtener informacion del producto
    SELECT
        unit_price,
        sku,
        name
    INTO STRICT
        v_precio,
        v_sku,
        v_producto
    FROM public.products
    WHERE product_id = p_producto_id;

    -- 5. Bloquear y validar inventario
    SELECT quantity_on_hand - quantity_reserved
    INTO STRICT v_stock
    FROM public.inventory
    WHERE warehouse_id = 1
      AND product_id = p_producto_id
    FOR UPDATE;

    IF v_stock < p_cantidad THEN
        RAISE EXCEPTION
            'Inventario insuficiente. Disponible: %, Solicitado: %',
            v_stock, p_cantidad;
    END IF;

    -- 6. Calcular total de venta
    v_total := ROUND(v_precio * p_cantidad, 2);

    -- 7. Generar numero unico de prueba
    v_numero_pedido :=
        'ORD-TEST-' ||
        LEFT(
            MD5(
                CLOCK_TIMESTAMP()::TEXT ||
                RANDOM()::TEXT
            ), 16
        );

    -- 8. Registrar pedido
    INSERT INTO public.orders (
        order_number,
        customer_id,
        shipping_address_id,
        status,
        subtotal,
        discount_amount,
        tax_amount,
        shipping_amount,
        total_amount
    )
    VALUES (
        v_numero_pedido,
        p_cliente_id,
        p_direccion_id,
        'PENDING',
        v_total,
        0,
        0,
        0,
        v_total
    )
    RETURNING order_id INTO v_order_id;

    -- 9. Registrar detalle del pedido
    -- El trigger descuenta inventario automaticamente
    INSERT INTO public.order_items (
        order_id,
        product_id,
        sku_snapshot,
        product_name_snapshot,
        quantity,
        unit_price,
        discount_amount,
        line_total
    )
    VALUES (
        v_order_id,
        p_producto_id,
        v_sku,
        v_producto,
        p_cantidad,
        v_precio,
        0,
        v_total
    );

    -- 10. Registrar pago
    INSERT INTO public.payments (
        order_id,
        payment_method,
        status,
        amount
    )
    VALUES (
        v_order_id,
        p_metodo_pago,
        'APPROVED',
        v_total
    );

    -- 11. Actualizar estado del pedido
    UPDATE public.orders
    SET status = 'PAID'
    WHERE order_id = v_order_id;

    -- 12. Confirmar resultado
    RAISE NOTICE
        'VENTA REGISTRADA: Pedido %, Total %, Unidades %',
        v_order_id,
        v_total,
        p_cantidad;

END;
$$;
