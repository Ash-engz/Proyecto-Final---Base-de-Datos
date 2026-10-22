-- ecommerce_db seed - MySQL 8.x
USE ecommerce_db;

INSERT INTO categories (name, slug) VALUES
('Tecnología', 'tecnologia'),
('Computación', 'computacion'),
('Hogar', 'hogar'),
('Audio', 'audio'),
('Accesorios', 'accesorios'),
('Oficina', 'oficina'),
('Videojuegos', 'videojuegos'),
('Electrodomésticos', 'electrodomesticos');

INSERT INTO products (sku, name, description, unit_price, cost_price) VALUES
('TEC-001','Laptop Ultrabook 14','Laptop para estudio y oficina',6499.00,5200.00),
('TEC-002','Laptop Gaming 15','Laptop para juegos y diseño',10999.00,8800.00),
('TEC-003','Monitor 24 pulgadas','Monitor IPS Full HD',1299.00,980.00),
('TEC-004','Monitor 27 pulgadas','Monitor QHD para productividad',2299.00,1800.00),
('ACC-001','Teclado mecánico','Teclado con switches táctiles',599.00,410.00),
('ACC-002','Mouse inalámbrico','Mouse ergonómico',249.00,150.00),
('ACC-003','Webcam Full HD','Cámara para videollamadas',399.00,260.00),
('ACC-004','Hub USB-C','Adaptador multipuerto',329.00,210.00),
('AUD-001','Audífonos Bluetooth','Audífonos con micrófono',449.00,300.00),
('AUD-002','Bocina portátil','Bocina resistente al agua',599.00,420.00),
('AUD-003','Barra de sonido','Audio para televisión',1199.00,860.00),
('HOG-001','Cafetera programable','Cafetera de 12 tazas',499.00,340.00),
('HOG-002','Licuadora 600W','Licuadora de uso doméstico',429.00,290.00),
('HOG-003','Freidora de aire','Freidora digital',899.00,650.00),
('HOG-004','Aspiradora compacta','Aspiradora para hogar',749.00,520.00),
('OFI-001','Silla ergonómica','Silla para oficina en casa',1399.00,1000.00),
('OFI-002','Escritorio ajustable','Escritorio de altura ajustable',2199.00,1650.00),
('OFI-003','Lámpara LED','Lámpara con intensidad regulable',279.00,170.00),
('VID-001','Control inalámbrico','Control compatible con PC',549.00,370.00),
('VID-002','Consola portátil','Consola de entretenimiento',2899.00,2350.00),
('VID-003','Silla gamer','Silla reclinable',1899.00,1400.00),
('COM-001','Disco SSD 1TB','Unidad de estado sólido',699.00,520.00),
('COM-002','Memoria RAM 16GB','Módulo DDR4',399.00,280.00),
('COM-003','Router WiFi 6','Router de doble banda',799.00,560.00),
('TEC-005','Tablet 10 pulgadas','Tablet para entretenimiento',1799.00,1350.00),
('ACC-005','Base para laptop','Base ajustable de aluminio',299.00,190.00),
('HOG-005','Horno eléctrico','Horno compacto de sobremesa',999.00,740.00),
('OFI-004','Archivador metálico','Archivador de oficina',899.00,650.00),
('AUD-004','Micrófono USB','Micrófono para streaming',699.00,470.00),
('COM-004','Teclado numérico','Teclado USB compacto',199.00,120.00);

INSERT INTO product_categories (product_id, category_id, is_primary)
SELECT product_id,
       CASE
         WHEN sku LIKE 'TEC-%' THEN 1
         WHEN sku LIKE 'COM-%' THEN 2
         WHEN sku LIKE 'HOG-%' THEN 3
         WHEN sku LIKE 'AUD-%' THEN 4
         WHEN sku LIKE 'ACC-%' THEN 5
         WHEN sku LIKE 'OFI-%' THEN 6
         WHEN sku LIKE 'VID-%' THEN 7
       END,
       TRUE
FROM products;

INSERT INTO product_categories(product_id, category_id, is_primary) VALUES
(1,2,FALSE),(2,2,FALSE),(3,6,FALSE),(4,6,FALSE),
(7,6,FALSE),(8,2,FALSE),(19,1,FALSE),(20,1,FALSE),
(22,1,FALSE),(23,1,FALSE),(24,1,FALSE),(25,2,FALSE);

INSERT INTO warehouses (code, name, city) VALUES
('GT-CEN','Centro de Distribución Central','Guatemala'),
('GT-OCC','Centro de Distribución Occidente','Quetzaltenango'),
('GT-SUR','Centro de Distribución Sur','Escuintla');

INSERT INTO coupons
(code, discount_type, discount_value, minimum_order_amount, valid_from, valid_to, usage_limit)
VALUES
('BIENVENIDA10','PERCENTAGE',10.00,200.00,'2026-05-01','2026-07-31',500),
('ENVIO25','FIXED',25.00,250.00,'2026-05-01','2026-07-31',300),
('JUNIO15','PERCENTAGE',15.00,500.00,'2026-06-01','2026-06-30',200),
('JULIO50','FIXED',50.00,700.00,'2026-07-01','2026-07-31',200);

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_seed_ecommerce$$
CREATE PROCEDURE sp_seed_ecommerce()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE d INT DEFAULT 0;
    DECLARE j INT DEFAULT 1;
    DECLARE v_customer_id BIGINT UNSIGNED;
    DECLARE v_address_id BIGINT UNSIGNED;
    DECLARE v_order_id BIGINT UNSIGNED;
    DECLARE v_product_1 BIGINT UNSIGNED;
    DECLARE v_product_2 BIGINT UNSIGNED;
    DECLARE v_qty_1 INT;
    DECLARE v_qty_2 INT;
    DECLARE v_price_1 DECIMAL(12,2);
    DECLARE v_price_2 DECIMAL(12,2);
    DECLARE v_subtotal DECIMAL(12,2);
    DECLARE v_discount DECIMAL(12,2);
    DECLARE v_tax DECIMAL(12,2);
    DECLARE v_shipping DECIMAL(12,2);
    DECLARE v_total DECIMAL(12,2);
    DECLARE v_order_date DATETIME;
    DECLARE v_status VARCHAR(20);
    DECLARE v_payment_status VARCHAR(20);
    DECLARE v_order_number VARCHAR(30);

    WHILE i <= 80 DO
        INSERT INTO customers
        (first_name,last_name,email,phone,status,created_at)
        VALUES(
            CONCAT('Cliente',LPAD(i,3,'0')),
            CONCAT('Apellido',LPAD(i,3,'0')),
            CONCAT('cliente',LPAD(i,3,'0'),'@correo.com'),
            CONCAT('5555-',LPAD(i,4,'0')),
            CASE WHEN MOD(i,19)=0 THEN 'INACTIVE' ELSE 'ACTIVE' END,
            DATE_ADD('2026-04-01 08:00:00', INTERVAL i DAY)
        );

        SET v_customer_id = LAST_INSERT_ID();

        INSERT INTO addresses
        (customer_id,address_type,line1,city,state_department,postal_code,country_code,is_default)
        VALUES(
            v_customer_id,'HOME',
            CONCAT('Avenida ',i,', casa ',100+i),
            CASE MOD(i,5)
              WHEN 0 THEN 'Guatemala'
              WHEN 1 THEN 'Mixco'
              WHEN 2 THEN 'Villa Nueva'
              WHEN 3 THEN 'Quetzaltenango'
              ELSE 'Escuintla'
            END,
            CASE MOD(i,5)
              WHEN 3 THEN 'Quetzaltenango'
              WHEN 4 THEN 'Escuintla'
              ELSE 'Guatemala'
            END,
            CONCAT('010',MOD(i,9)+1),'GT',TRUE
        );

        IF MOD(i,4)=0 THEN
            INSERT INTO addresses
            (customer_id,address_type,line1,city,state_department,postal_code,country_code,is_default)
            VALUES(
                v_customer_id,'WORK',
                CONCAT('Oficina ',i,', zona ',MOD(i,15)+1),
                'Guatemala','Guatemala','01001','GT',FALSE
            );
        END IF;

        INSERT INTO carts(customer_id,status,created_at)
        VALUES(
            v_customer_id,
            CASE WHEN MOD(i,7)=0 THEN 'ABANDONED'
                 WHEN MOD(i,5)=0 THEN 'CONVERTED'
                 ELSE 'OPEN' END,
            DATE_ADD('2026-07-20 10:00:00',INTERVAL i HOUR)
        );

        SET i = i + 1;
    END WHILE;

    INSERT INTO inventory
    (warehouse_id,product_id,quantity_on_hand,quantity_reserved,reorder_point)
    SELECT
        w.warehouse_id,p.product_id,
        CASE
          WHEN MOD(p.product_id+w.warehouse_id,9)=0 THEN 25
          WHEN MOD(p.product_id+w.warehouse_id,7)=0 THEN 45
          ELSE 400 + MOD(p.product_id*w.warehouse_id,120)
        END,
        MOD(p.product_id*w.warehouse_id,12),
        40
    FROM warehouses w
    CROSS JOIN products p;

    INSERT INTO cart_items(cart_id,product_id,quantity,unit_price)
    SELECT c.cart_id,
           1 + MOD(c.cart_id*3,30),
           1 + MOD(c.cart_id,3),
           p.unit_price
    FROM carts c
    JOIN products p ON p.product_id = 1 + MOD(c.cart_id*3,30)
    WHERE c.status <> 'ABANDONED';

    WHILE d < 92 DO
        SET j = 1;
        WHILE j <= 14 DO
            SET v_customer_id = 1 + MOD((d*14)+j-1,80);

            SELECT address_id INTO v_address_id
            FROM addresses
            WHERE customer_id=v_customer_id AND is_default=TRUE
            LIMIT 1;

            SET v_product_1 = 1 + MOD((d*7)+j,30);
            SET v_product_2 = 1 + MOD((d*11)+(j*3),30);
            IF v_product_2=v_product_1 THEN
                SET v_product_2 = 1 + MOD(v_product_2,30);
            END IF;

            SET v_qty_1 = 1 + MOD(j,3);
            SET v_qty_2 = 1 + MOD(d+j,2);

            SELECT unit_price INTO v_price_1 FROM products WHERE product_id=v_product_1;
            SELECT unit_price INTO v_price_2 FROM products WHERE product_id=v_product_2;

            SET v_subtotal = ROUND((v_qty_1*v_price_1)+(v_qty_2*v_price_2),2);
            SET v_discount =
                CASE
                  WHEN MOD(d*14+j,18)=0 THEN LEAST(ROUND(v_subtotal*0.15,2),400.00)
                  WHEN MOD(d*14+j,11)=0 THEN LEAST(ROUND(v_subtotal*0.10,2),250.00)
                  ELSE 0.00
                END;
            SET v_tax = ROUND((v_subtotal-v_discount)*0.12,2);
            SET v_shipping = CASE WHEN v_subtotal >= 700 THEN 0 ELSE 35 END;
            SET v_total = ROUND(v_subtotal-v_discount+v_tax+v_shipping,2);

            SET v_status =
                CASE
                  WHEN MOD(d*14+j,23)=0 THEN 'CANCELLED'
                  WHEN d >= 89 THEN 'PENDING'
                  WHEN d >= 87 THEN 'PROCESSING'
                  WHEN d >= 84 THEN 'SHIPPED'
                  WHEN MOD(d*14+j,13)=0 THEN 'PAID'
                  ELSE 'DELIVERED'
                END;

            SET v_order_date = DATE_ADD(
                DATE_ADD('2026-05-01 08:00:00',INTERVAL d DAY),
                INTERVAL (j*41) MINUTE
            );

            SET v_order_number = CONCAT(
                'ORD-',DATE_FORMAT(v_order_date,'%Y%m%d'),'-',LPAD(j,3,'0')
            );

            INSERT INTO orders
            (order_number,customer_id,shipping_address_id,status,subtotal,
             discount_amount,tax_amount,shipping_amount,total_amount,ordered_at)
            VALUES(
                v_order_number,v_customer_id,v_address_id,v_status,v_subtotal,
                v_discount,v_tax,v_shipping,v_total,v_order_date
            );

            SET v_order_id = LAST_INSERT_ID();

            INSERT INTO order_items
            (order_id,product_id,sku_snapshot,product_name_snapshot,quantity,
             unit_price,discount_amount,line_total)
            SELECT v_order_id,product_id,sku,name,v_qty_1,unit_price,0.00,
                   ROUND(v_qty_1*unit_price,2)
            FROM products WHERE product_id=v_product_1;

            INSERT INTO order_items
            (order_id,product_id,sku_snapshot,product_name_snapshot,quantity,
             unit_price,discount_amount,line_total)
            SELECT v_order_id,product_id,sku,name,v_qty_2,unit_price,0.00,
                   ROUND(v_qty_2*unit_price,2)
            FROM products WHERE product_id=v_product_2;

            SET v_payment_status =
                CASE WHEN v_status='CANCELLED' THEN 'REJECTED'
                     WHEN v_status='PENDING' THEN 'PENDING'
                     ELSE 'APPROVED' END;

            INSERT INTO payments
            (order_id,payment_method,status,amount,transaction_reference,paid_at,created_at)
            VALUES(
                v_order_id,
                CASE MOD(j,4)
                  WHEN 0 THEN 'CARD'
                  WHEN 1 THEN 'TRANSFER'
                  WHEN 2 THEN 'WALLET'
                  ELSE 'CASH_ON_DELIVERY'
                END,
                v_payment_status,v_total,
                CONCAT('TX-',LPAD(v_order_id,9,'0')),
                CASE WHEN v_payment_status='APPROVED'
                     THEN DATE_ADD(v_order_date,INTERVAL 10 MINUTE)
                     ELSE NULL END,
                v_order_date
            );

            IF v_status IN ('PROCESSING','SHIPPED','DELIVERED') THEN
                INSERT INTO shipments
                (order_id,warehouse_id,carrier,tracking_number,status,shipped_at,delivered_at)
                VALUES(
                    v_order_id,
                    1+MOD(j,3),
                    CASE MOD(j,3)
                      WHEN 0 THEN 'Cargo Express'
                      WHEN 1 THEN 'Guatex'
                      ELSE 'Forza Delivery'
                    END,
                    CONCAT('TRK-',LPAD(v_order_id,10,'0')),
                    CASE WHEN v_status='PROCESSING' THEN 'PREPARING'
                         WHEN v_status='SHIPPED' THEN 'IN_TRANSIT'
                         ELSE 'DELIVERED' END,
                    CASE WHEN v_status IN ('SHIPPED','DELIVERED')
                         THEN DATE_ADD(v_order_date,INTERVAL 1 DAY)
                         ELSE NULL END,
                    CASE WHEN v_status='DELIVERED'
                         THEN DATE_ADD(v_order_date,INTERVAL 2 + MOD(j,3) DAY)
                         ELSE NULL END
                );
            END IF;

            IF v_discount > 0 THEN
                INSERT INTO order_coupons(order_id,coupon_id,discount_applied)
                VALUES(
                    v_order_id,
                    CASE WHEN MONTH(v_order_date)=6 THEN 3
                         WHEN MONTH(v_order_date)=7 THEN 4
                         ELSE 1 END,
                    v_discount
                );
            END IF;

            SET j = j + 1;
        END WHILE;
        SET d = d + 1;
    END WHILE;
END$$

DELIMITER ;

CALL sp_seed_ecommerce();
DROP PROCEDURE sp_seed_ecommerce;

SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'payments', COUNT(*) FROM payments
UNION ALL SELECT 'shipments', COUNT(*) FROM shipments;

SELECT
    MIN(ordered_at) AS first_order,
    MAX(ordered_at) AS last_order,
    COUNT(*) AS total_orders
FROM orders;

SELECT
    DATE_FORMAT(ordered_at,'%Y-%m') AS month,
    COUNT(*) AS total_orders,
    ROUND(SUM(total_amount),2) AS total_amount
FROM orders
GROUP BY DATE_FORMAT(ordered_at,'%Y-%m')
ORDER BY month;
