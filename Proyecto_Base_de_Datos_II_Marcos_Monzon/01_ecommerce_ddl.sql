-- ecommerce_db DDL - MySQL 8.x
DROP DATABASE IF EXISTS ecommerce_db;
CREATE DATABASE ecommerce_db CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE ecommerce_db;

CREATE TABLE customers (
    customer_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(80) NOT NULL,
    last_name VARCHAR(80) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    phone VARCHAR(30),
    status ENUM('ACTIVE','INACTIVE','BLOCKED') NOT NULL DEFAULT 'ACTIVE',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT chk_customers_email CHECK (email LIKE '%_@_%._%')
) ENGINE=InnoDB;

CREATE TABLE addresses (
    address_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id BIGINT UNSIGNED NOT NULL,
    address_type ENUM('HOME','WORK','OTHER') NOT NULL DEFAULT 'HOME',
    line1 VARCHAR(180) NOT NULL,
    line2 VARCHAR(180),
    city VARCHAR(100) NOT NULL,
    state_department VARCHAR(100) NOT NULL,
    postal_code VARCHAR(20),
    country_code CHAR(2) NOT NULL DEFAULT 'GT',
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_addresses_customer FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE categories (
    category_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    parent_category_id INT UNSIGNED NULL,
    name VARCHAR(100) NOT NULL UNIQUE,
    slug VARCHAR(120) NOT NULL UNIQUE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_categories_parent FOREIGN KEY (parent_category_id)
        REFERENCES categories(category_id) ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE products (
    product_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    sku VARCHAR(40) NOT NULL UNIQUE,
    name VARCHAR(180) NOT NULL,
    description TEXT,
    unit_price DECIMAL(12,2) NOT NULL,
    cost_price DECIMAL(12,2) NOT NULL,
    status ENUM('ACTIVE','INACTIVE','DISCONTINUED') NOT NULL DEFAULT 'ACTIVE',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT chk_products_unit_price CHECK (unit_price >= 0),
    CONSTRAINT chk_products_cost_price CHECK (cost_price >= 0),
    CONSTRAINT chk_products_margin CHECK (unit_price >= cost_price)
) ENGINE=InnoDB;

CREATE TABLE product_categories (
    product_id BIGINT UNSIGNED NOT NULL,
    category_id INT UNSIGNED NOT NULL,
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (product_id, category_id),
    CONSTRAINT fk_product_categories_product FOREIGN KEY (product_id)
        REFERENCES products(product_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_product_categories_category FOREIGN KEY (category_id)
        REFERENCES categories(category_id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE warehouses (
    warehouse_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(120) NOT NULL,
    city VARCHAR(100) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;

CREATE TABLE inventory (
    warehouse_id INT UNSIGNED NOT NULL,
    product_id BIGINT UNSIGNED NOT NULL,
    quantity_on_hand INT NOT NULL DEFAULT 0,
    quantity_reserved INT NOT NULL DEFAULT 0,
    reorder_point INT NOT NULL DEFAULT 10,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (warehouse_id, product_id),
    CONSTRAINT fk_inventory_warehouse FOREIGN KEY (warehouse_id)
        REFERENCES warehouses(warehouse_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_inventory_product FOREIGN KEY (product_id)
        REFERENCES products(product_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT chk_inventory_on_hand CHECK (quantity_on_hand >= 0),
    CONSTRAINT chk_inventory_reserved CHECK (quantity_reserved >= 0),
    CONSTRAINT chk_inventory_available CHECK (quantity_reserved <= quantity_on_hand)
) ENGINE=InnoDB;

CREATE TABLE carts (
    cart_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id BIGINT UNSIGNED NOT NULL,
    status ENUM('OPEN','CONVERTED','ABANDONED') NOT NULL DEFAULT 'OPEN',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_carts_customer FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE cart_items (
    cart_id BIGINT UNSIGNED NOT NULL,
    product_id BIGINT UNSIGNED NOT NULL,
    quantity INT UNSIGNED NOT NULL,
    unit_price DECIMAL(12,2) NOT NULL,
    added_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (cart_id, product_id),
    CONSTRAINT fk_cart_items_cart FOREIGN KEY (cart_id)
        REFERENCES carts(cart_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_cart_items_product FOREIGN KEY (product_id)
        REFERENCES products(product_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_cart_items_quantity CHECK (quantity > 0),
    CONSTRAINT chk_cart_items_price CHECK (unit_price >= 0)
) ENGINE=InnoDB;

CREATE TABLE coupons (
    coupon_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(30) NOT NULL UNIQUE,
    discount_type ENUM('PERCENTAGE','FIXED') NOT NULL,
    discount_value DECIMAL(10,2) NOT NULL,
    minimum_order_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    valid_from DATE NOT NULL,
    valid_to DATE NOT NULL,
    usage_limit INT UNSIGNED,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT chk_coupons_value CHECK (discount_value > 0),
    CONSTRAINT chk_coupons_dates CHECK (valid_to >= valid_from)
) ENGINE=InnoDB;

CREATE TABLE orders (
    order_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_number VARCHAR(30) NOT NULL UNIQUE,
    customer_id BIGINT UNSIGNED NOT NULL,
    shipping_address_id BIGINT UNSIGNED NOT NULL,
    status ENUM('PENDING','PAID','PROCESSING','SHIPPED','DELIVERED','CANCELLED') NOT NULL DEFAULT 'PENDING',
    subtotal DECIMAL(12,2) NOT NULL,
    discount_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    tax_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    shipping_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    total_amount DECIMAL(12,2) NOT NULL,
    ordered_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_orders_shipping_address FOREIGN KEY (shipping_address_id)
        REFERENCES addresses(address_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_orders_amounts CHECK (
        subtotal >= 0 AND discount_amount >= 0 AND tax_amount >= 0
        AND shipping_amount >= 0 AND total_amount >= 0
    )
) ENGINE=InnoDB;

CREATE TABLE order_items (
    order_item_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT UNSIGNED NOT NULL,
    product_id BIGINT UNSIGNED NOT NULL,
    sku_snapshot VARCHAR(40) NOT NULL,
    product_name_snapshot VARCHAR(180) NOT NULL,
    quantity INT UNSIGNED NOT NULL,
    unit_price DECIMAL(12,2) NOT NULL,
    discount_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    line_total DECIMAL(12,2) NOT NULL,
    CONSTRAINT fk_order_items_order FOREIGN KEY (order_id)
        REFERENCES orders(order_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_order_items_product FOREIGN KEY (product_id)
        REFERENCES products(product_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_order_items_quantity CHECK (quantity > 0),
    CONSTRAINT chk_order_items_prices CHECK (
        unit_price >= 0 AND discount_amount >= 0 AND line_total >= 0
    )
) ENGINE=InnoDB;

CREATE TABLE payments (
    payment_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT UNSIGNED NOT NULL,
    payment_method ENUM('CARD','TRANSFER','CASH_ON_DELIVERY','WALLET') NOT NULL,
    status ENUM('PENDING','APPROVED','REJECTED','REFUNDED') NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    transaction_reference VARCHAR(80) UNIQUE,
    paid_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_payments_order FOREIGN KEY (order_id)
        REFERENCES orders(order_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT chk_payments_amount CHECK (amount > 0)
) ENGINE=InnoDB;

CREATE TABLE shipments (
    shipment_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT UNSIGNED NOT NULL,
    warehouse_id INT UNSIGNED NOT NULL,
    carrier VARCHAR(80) NOT NULL,
    tracking_number VARCHAR(80) UNIQUE,
    status ENUM('PENDING','PREPARING','IN_TRANSIT','DELIVERED','FAILED') NOT NULL,
    shipped_at DATETIME NULL,
    delivered_at DATETIME NULL,
    CONSTRAINT fk_shipments_order FOREIGN KEY (order_id)
        REFERENCES orders(order_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_shipments_warehouse FOREIGN KEY (warehouse_id)
        REFERENCES warehouses(warehouse_id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE order_coupons (
    order_id BIGINT UNSIGNED NOT NULL,
    coupon_id INT UNSIGNED NOT NULL,
    discount_applied DECIMAL(12,2) NOT NULL,
    PRIMARY KEY (order_id, coupon_id),
    CONSTRAINT fk_order_coupons_order FOREIGN KEY (order_id)
        REFERENCES orders(order_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_order_coupons_coupon FOREIGN KEY (coupon_id)
        REFERENCES coupons(coupon_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_order_coupons_discount CHECK (discount_applied > 0)
) ENGINE=InnoDB;

CREATE INDEX idx_addresses_customer ON addresses(customer_id);
CREATE INDEX idx_products_name ON products(name);
CREATE INDEX idx_inventory_product ON inventory(product_id);
CREATE INDEX idx_carts_customer_status ON carts(customer_id, status);
CREATE INDEX idx_orders_customer_date ON orders(customer_id, ordered_at);
CREATE INDEX idx_orders_status_date ON orders(status, ordered_at);
CREATE INDEX idx_order_items_product ON order_items(product_id);
CREATE INDEX idx_payments_order_status ON payments(order_id, status);
CREATE INDEX idx_shipments_order_status ON shipments(order_id, status);

SHOW TABLES;
