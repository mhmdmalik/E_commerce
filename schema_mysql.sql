
DROP TABLE IF EXISTS users;
CREATE TABLE users (
  id CHAR(36) NOT NULL PRIMARY KEY DEFAULT (UUID()),
  email VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  full_name VARCHAR(255),
  phone VARCHAR(50),
  role VARCHAR(50) NOT NULL DEFAULT 'customer', -- 'customer','admin','support'
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  last_login_at TIMESTAMP NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Addresses
DROP TABLE IF EXISTS addresses;
CREATE TABLE addresses (
  id CHAR(36) NOT NULL PRIMARY KEY DEFAULT (UUID()),
  user_id CHAR(36) NOT NULL,
  label VARCHAR(50),
  recipient_name VARCHAR(255),
  line1 VARCHAR(500) NOT NULL,
  line2 VARCHAR(500),
  city VARCHAR(255) NOT NULL,
  state VARCHAR(255),
  postal_code VARCHAR(50),
  country VARCHAR(50) NOT NULL DEFAULT 'IN',
  phone VARCHAR(50),
  is_default TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_addresses_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_addresses_user ON addresses(user_id);

-- ------------------------------
-- CATALOG: categories, products, variants
-- ------------------------------
DROP TABLE IF EXISTS categories;
CREATE TABLE categories (
  id CHAR(36) NOT NULL PRIMARY KEY DEFAULT (UUID()),
  name VARCHAR(255) NOT NULL,
  slug VARCHAR(255) NOT NULL UNIQUE,
  parent_id CHAR(36) DEFAULT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_categories_parent FOREIGN KEY (parent_id) REFERENCES categories(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DROP TABLE IF EXISTS products;
CREATE TABLE products (
  id CHAR(36) NOT NULL PRIMARY KEY DEFAULT (UUID()),
  sku VARCHAR(100) UNIQUE,
  name VARCHAR(500) NOT NULL,
  description TEXT,
  brand VARCHAR(255),
  category_id CHAR(36) DEFAULT NULL,
  active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_products_category FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DROP TABLE IF EXISTS product_variants;
CREATE TABLE product_variants (
  id CHAR(36) NOT NULL PRIMARY KEY DEFAULT (UUID()),
  product_id CHAR(36) NOT NULL,
  sku VARCHAR(150) NOT NULL UNIQUE,
  title VARCHAR(255),
  attributes JSON,
  price DECIMAL(12,2) NOT NULL,
  msrp DECIMAL(12,2),
  active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_variants_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_variants_product ON product_variants(product_id);
CREATE INDEX idx_variants_price ON product_variants(price);

-- ------------------------------
-- INVENTORY (supports multiple warehouses)
-- ------------------------------
DROP TABLE IF EXISTS warehouses;
CREATE TABLE warehouses (
  id CHAR(36) NOT NULL PRIMARY KEY DEFAULT (UUID()),
  name VARCHAR(255) NOT NULL,
  location VARCHAR(255)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DROP TABLE IF EXISTS inventory;
CREATE TABLE inventory (
  id CHAR(36) NOT NULL PRIMARY KEY DEFAULT (UUID()),
  variant_id CHAR(36) NOT NULL,
  warehouse_id CHAR(36) NOT NULL,
  qty_available BIGINT NOT NULL DEFAULT 0,
  qty_reserved BIGINT NOT NULL DEFAULT 0,
  last_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_inventory_variant FOREIGN KEY (variant_id) REFERENCES product_variants(id) ON DELETE CASCADE,
  CONSTRAINT fk_inventory_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(id) ON DELETE CASCADE,
  UNIQUE KEY uq_inventory_variant_warehouse (variant_id, warehouse_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------
-- MV-like table to store aggregated stock per variant
-- ------------------------------
DROP TABLE IF EXISTS mv_variant_stock;
CREATE TABLE mv_variant_stock (
  variant_id CHAR(36) NOT NULL PRIMARY KEY,
  total_available BIGINT NOT NULL DEFAULT 0,
  last_refreshed TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_mv_variant_stock_variant ON mv_variant_stock(variant_id);

-- ------------------------------
-- ORDERS & ORDER ITEMS
-- ------------------------------
-- order status
DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
  id CHAR(36) NOT NULL PRIMARY KEY DEFAULT (UUID()),
  order_number VARCHAR(100) NOT NULL UNIQUE,
  user_id CHAR(36),
  billing_address_id CHAR(36),
  shipping_address_id CHAR(36),
  status ENUM('pending','confirmed','processing','shipped','delivered','cancelled','refunded') NOT NULL DEFAULT 'pending',
  subtotal DECIMAL(12,2) NOT NULL DEFAULT 0,
  shipping_cost DECIMAL(12,2) NOT NULL DEFAULT 0,
  discount_total DECIMAL(12,2) NOT NULL DEFAULT 0,
  tax_total DECIMAL(12,2) NOT NULL DEFAULT 0,
  total DECIMAL(12,2) NOT NULL DEFAULT 0,
  currency VARCHAR(10) NOT NULL DEFAULT 'INR',
  placed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  metadata JSON,
  CONSTRAINT fk_orders_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT fk_orders_billing_addr FOREIGN KEY (billing_address_id) REFERENCES addresses(id),
  CONSTRAINT fk_orders_shipping_addr FOREIGN KEY (shipping_address_id) REFERENCES addresses(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_orders_user ON orders(user_id);
CREATE INDEX idx_orders_placed_at ON orders(placed_at);

DROP TABLE IF EXISTS order_items;
CREATE TABLE order_items (
  id CHAR(36) NOT NULL PRIMARY KEY DEFAULT (UUID()),
  order_id CHAR(36) NOT NULL,
  variant_id CHAR(36) NOT NULL,
  quantity INT NOT NULL,
  unit_price DECIMAL(12,2) NOT NULL,
  line_total DECIMAL(12,2) NOT NULL,
  sku_snapshot VARCHAR(150),
  attributes_snapshot JSON,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_orderitems_order FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
  CONSTRAINT fk_orderitems_variant FOREIGN KEY (variant_id) REFERENCES product_variants(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_order_items_order ON order_items(order_id);

-- ------------------------------
-- PAYMENTS
-- ------------------------------
DROP TABLE IF EXISTS payments;
CREATE TABLE payments (
  id CHAR(36) NOT NULL PRIMARY KEY DEFAULT (UUID()),
  order_id CHAR(36) NOT NULL,
  provider VARCHAR(100) NOT NULL,
  provider_transaction_id VARCHAR(255),
  status ENUM('initiated','authorized','captured','failed','refunded') NOT NULL DEFAULT 'initiated',
  amount DECIMAL(12,2) NOT NULL,
  currency VARCHAR(10) NOT NULL DEFAULT 'INR',
  paid_at TIMESTAMP NULL DEFAULT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  metadata JSON,
  CONSTRAINT fk_payments_order FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_payments_order ON payments(order_id);

-- ------------------------------
-- SHIPMENTS
-- ------------------------------
DROP TABLE IF EXISTS shipments;
CREATE TABLE shipments (
  id CHAR(36) NOT NULL PRIMARY KEY DEFAULT (UUID()),
  order_id CHAR(36) NOT NULL,
  carrier VARCHAR(255),
  tracking_number VARCHAR(255),
  status ENUM('pending','packed','in_transit','delivered','returned') NOT NULL DEFAULT 'pending',
  shipped_at TIMESTAMP NULL DEFAULT NULL,
  delivered_at TIMESTAMP NULL DEFAULT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_shipments_order FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_shipments_order ON shipments(order_id);

-- ------------------------------
-- COUPONS
-- ------------------------------
DROP TABLE IF EXISTS coupons;
CREATE TABLE coupons (
  id CHAR(36) NOT NULL PRIMARY KEY DEFAULT (UUID()),
  code VARCHAR(100) NOT NULL UNIQUE,
  description TEXT,
  discount_type ENUM('percentage','fixed') NOT NULL,
  discount_value DECIMAL(12,2) NOT NULL,
  min_order_value DECIMAL(12,2) DEFAULT 0,
  valid_from TIMESTAMP NULL DEFAULT NULL,
  valid_until TIMESTAMP NULL DEFAULT NULL,
  usage_limit INT DEFAULT NULL,
  times_used INT DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------
-- REVIEWS
-- ------------------------------
DROP TABLE IF EXISTS reviews;
CREATE TABLE reviews (
  id CHAR(36) NOT NULL PRIMARY KEY DEFAULT (UUID()),
  user_id CHAR(36),
  product_id CHAR(36),
  rating SMALLINT CHECK (rating >= 1 AND rating <= 5),
  title VARCHAR(255),
  body TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_reviews_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT fk_reviews_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_reviews_product ON reviews(product_id);

-- ------------------------------
-- AUDIT LOGS
-- ------------------------------
DROP TABLE IF EXISTS audit_logs;
CREATE TABLE audit_logs (
  id CHAR(36) NOT NULL PRIMARY KEY DEFAULT (UUID()),
  entity_type VARCHAR(100) NOT NULL,
  entity_id CHAR(36),
  action VARCHAR(100) NOT NULL,
  performed_by CHAR(36) NULL,
  -- JSON change detail
  change JSON,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_audit_performed_by FOREIGN KEY (performed_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------
-- SAMPLE DATA (small set)
-- ------------------------------
-- Users
INSERT INTO users (email, password_hash, full_name, role)
VALUES
('alice@example.com', '$2y$12$EXAMPLEHASH', 'Alice Adams', 'customer'),
('bob@example.com', '$2y$12$EXAMPLEHASH2', 'Bob Brown', 'customer'),
('admin@acme.com', '$2y$12$ADMINHASH', 'Admin User', 'admin');

-- Addresses
INSERT INTO addresses (user_id, label, recipient_name, line1, city, state, postal_code, country, phone, is_default)
VALUES
((SELECT id FROM users WHERE email='alice@example.com'), 'home', 'Alice Adams', '123 Main St', 'Bengaluru', 'Karnataka', '560001', 'IN', '9999999999', 1),
((SELECT id FROM users WHERE email='bob@example.com'), 'home', 'Bob Brown', '456 Market St', 'Hyderabad', 'Telangana', '500001', 'IN', '8888888888', 1);

-- Warehouses
INSERT INTO warehouses (name, location) VALUES ('Main WH', 'Bengaluru'), ('Secondary WH','Hyderabad');

-- Categories
INSERT INTO categories (name, slug) VALUES ('Apparel','apparel'), ('Electronics','electronics');

-- Product and variant for T-Shirt
INSERT INTO products (sku, name, description, category_id)
VALUES ('PRD-TSHIRT','T-Shirt','Comfort cotton tee', (SELECT id FROM categories WHERE slug='apparel' LIMIT 1));

-- Variant
INSERT INTO product_variants (product_id, sku, title, attributes, price)
VALUES (
  (SELECT id FROM products WHERE sku='PRD-TSHIRT' LIMIT 1),
  'TSHIRT-RED-L',
  'Red - L',
  JSON_OBJECT('color','red','size','L'),
  399.00
);

-- Inventory for variant
INSERT INTO inventory (variant_id, warehouse_id, qty_available, qty_reserved)
VALUES (
  (SELECT id FROM product_variants WHERE sku='TSHIRT-RED-L' LIMIT 1),
  (SELECT id FROM warehouses LIMIT 1),
  100, 0
);

-- Refresh aggregated stock table
TRUNCATE TABLE mv_variant_stock;
INSERT INTO mv_variant_stock (variant_id, total_available, last_refreshed)
SELECT v.id, COALESCE(SUM(i.qty_available - i.qty_reserved),0), NOW()
FROM product_variants v
LEFT JOIN inventory i ON i.variant_id = v.id
GROUP BY v.id;

-- ------------------------------
-- Stored procedure: sp_place_order
-- ------------------------------
DELIMITER $$
DROP PROCEDURE IF EXISTS sp_place_order $$
CREATE PROCEDURE sp_place_order (
  IN p_user_id CHAR(36),
  IN p_shipping_address_id CHAR(36),
  IN p_items JSON,
  IN p_payment_provider VARCHAR(100),
  IN p_currency VARCHAR(10)
)
BEGIN
  DECLARE v_order_id CHAR(36);
  DECLARE v_order_number VARCHAR(100);
  DECLARE v_subtotal DECIMAL(12,2) DEFAULT 0;
  DECLARE v_len INT DEFAULT 0;
  DECLARE i INT DEFAULT 0;
  DECLARE v_variant_id CHAR(36);
  DECLARE v_qty INT;
  DECLARE v_price DECIMAL(12,2);
  DECLARE v_line_total DECIMAL(12,2);
  DECLARE v_inventory_id CHAR(36);

  -- Validate user exists
  IF NOT EXISTS (SELECT 1 FROM users WHERE id = p_user_id) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'User not found';
  END IF;

  -- Compute number of items
  SET v_len = JSON_LENGTH(p_items);

  IF v_len = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No items provided';
  END IF;

  -- Start transaction
  START TRANSACTION;

  -- Generate order id & order number
  SET v_order_id = UUID();
  SET v_order_number = CONCAT('ORD-', DATE_FORMAT(NOW(), '%Y%m%d%H%i%s'), '-', SUBSTRING(v_order_id,1,8));

  -- Loop through items: validate, check stock, and reserve
  SET i = 0;
  WHILE i < v_len DO
    SET v_variant_id = JSON_UNQUOTE(JSON_EXTRACT(p_items, CONCAT('$[', i, '].variant_id')));
    SET v_qty = CAST(JSON_EXTRACT(p_items, CONCAT('$[', i, '].quantity')) AS UNSIGNED);

    -- Check variant exists and get price
    SELECT price INTO v_price FROM product_variants WHERE id = v_variant_id;
    IF v_price IS NULL THEN
      ROLLBACK;
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = CONCAT('Variant not found: ', v_variant_id);
    END IF;

    -- Check availability across inventory: find a row with (qty_available - qty_reserved) >= v_qty
    -- Select inventory row FOR UPDATE to lock it and then update qty_reserved
    SELECT id INTO v_inventory_id
    FROM inventory
    WHERE variant_id = v_variant_id AND (qty_available - qty_reserved) >= v_qty
    ORDER BY (qty_available - qty_reserved) DESC
    LIMIT 1
    FOR UPDATE;

    IF v_inventory_id IS NULL THEN
      ROLLBACK;
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = CONCAT('Insufficient stock for variant: ', v_variant_id);
    END IF;

    -- Reserve it
    UPDATE inventory
    SET qty_reserved = qty_reserved + v_qty, last_updated = NOW()
    WHERE id = v_inventory_id;

    -- accumulate subtotal
    SET v_line_total = v_price * v_qty;
    SET v_subtotal = v_subtotal + v_line_total;

    SET i = i + 1;
  END WHILE;

  -- Create order
  INSERT INTO orders (id, order_number, user_id, shipping_address_id, subtotal, shipping_cost, discount_total, tax_total, total, currency, placed_at, updated_at)
  VALUES (v_order_id, v_order_number, p_user_id, p_shipping_address_id, v_subtotal, 0, 0, 0, v_subtotal, COALESCE(p_currency,'INR'), NOW(), NOW());

  -- Insert order items (loop again)
  SET i = 0;
  WHILE i < v_len DO
    SET v_variant_id = JSON_UNQUOTE(JSON_EXTRACT(p_items, CONCAT('$[', i, '].variant_id')));
    SET v_qty = CAST(JSON_EXTRACT(p_items, CONCAT('$[', i, '].quantity')) AS UNSIGNED);
    SELECT price INTO v_price FROM product_variants WHERE id = v_variant_id;
    SET v_line_total = v_price * v_qty;

    INSERT INTO order_items (id, order_id, variant_id, quantity, unit_price, line_total, sku_snapshot, attributes_snapshot, created_at)
    VALUES (UUID(), v_order_id, v_variant_id, v_qty, v_price, v_line_total,
            (SELECT sku FROM product_variants WHERE id = v_variant_id),
            (SELECT attributes FROM product_variants WHERE id = v_variant_id),
            NOW());
    SET i = i + 1;
  END WHILE;

  -- Create payment record (initiated)
  INSERT INTO payments (id, order_id, provider, amount, currency, status, created_at)
  VALUES (UUID(), v_order_id, p_payment_provider, v_subtotal, COALESCE(p_currency,'INR'), 'initiated', NOW());

  -- Audit log
  INSERT INTO audit_logs (id, entity_type, entity_id, action, performed_by, change, created_at)
  VALUES (UUID(), 'order', v_order_id, 'created', p_user_id, JSON_OBJECT('subtotal', v_subtotal), NOW());

  COMMIT;

  -- Return order id & number — MySQL SP can't return directly but you can SELECT to see them
  SELECT v_order_id AS order_id, v_order_number AS order_number;
END $$
DELIMITER ;

-- ------------------------------
-- Trigger: trg_orders_after_update
-- ------------------------------
DELIMITER $$
DROP TRIGGER IF EXISTS trg_orders_after_update $$
CREATE TRIGGER trg_orders_after_update
AFTER UPDATE ON orders
FOR EACH ROW
BEGIN
  -- Audit on status change
  IF NOT (OLD.status <=> NEW.status) THEN
    INSERT INTO audit_logs (id, entity_type, entity_id, action, performed_by, change, created_at)
    VALUES (UUID(), 'order', NEW.id, 'status_changed', NULL,
            JSON_OBJECT('from', OLD.status, 'to', NEW.status), NOW());
  END IF;

  -- If cancelled or refunded -> release reserved inventory
  IF NEW.status IN ('cancelled','refunded') THEN
    -- Release reserved qty for each order_item: reduce qty_reserved = GREATEST(qty_reserved - quantity, 0)
    UPDATE inventory i
    JOIN (
      SELECT variant_id, SUM(quantity) AS qty_to_release
      FROM order_items
      WHERE order_id = NEW.id
      GROUP BY variant_id
    ) oi ON oi.variant_id = i.variant_id
    SET i.qty_reserved = GREATEST(i.qty_reserved - oi.qty_to_release, 0),
        i.last_updated = NOW();
    INSERT INTO audit_logs (id, entity_type, entity_id, action, performed_by, change, created_at)
    VALUES (UUID(), 'order', NEW.id, 'inventory_released', NULL, JSON_OBJECT('status', NEW.status), NOW());
  END IF;
END $$
DELIMITER ;

-- ------------------------------
-- Materialized-view-like refresh procedure and optional event
-- ------------------------------
DELIMITER $$
DROP PROCEDURE IF EXISTS sp_refresh_mv_variant_stock $$
CREATE PROCEDURE sp_refresh_mv_variant_stock()
BEGIN
  -- Truncate and recompute
  TRUNCATE TABLE mv_variant_stock;
  INSERT INTO mv_variant_stock (variant_id, total_available, last_refreshed)
  SELECT v.id AS variant_id,
         COALESCE(SUM(i.qty_available - i.qty_reserved),0) AS total_available,
         NOW()
  FROM product_variants v
  LEFT JOIN inventory i ON i.variant_id = v.id
  GROUP BY v.id;
END $$
DELIMITER ;

-- Run it once:
CALL sp_refresh_mv_variant_stock();

-- Optionally, enable event scheduler to refresh hourly (requires global privilege and event scheduler ON)
-- SET GLOBAL event_scheduler = ON;
-- CREATE EVENT ev_refresh_variant_stock
-- ON SCHEDULE EVERY 1 HOUR
-- DO CALL sp_refresh_mv_variant_stock();

-- ------------------------------
-- Reporting queries (examples)
-- ------------------------------
-- 1) Sales summary by day (last 30 days)
-- SELECT DATE(placed_at) AS day, COUNT(*) AS orders, SUM(total) AS revenue
-- FROM orders
-- WHERE placed_at >= NOW() - INTERVAL 30 DAY
-- GROUP BY DATE(placed_at)
-- ORDER BY day DESC;

-- 2) Top 10 selling variants (units & revenue) last 30 days
-- SELECT oi.variant_id, pv.sku, pv.title, SUM(oi.quantity) AS units_sold, SUM(oi.line_total) AS revenue
-- FROM order_items oi
-- JOIN orders o ON o.id = oi.order_id
-- JOIN product_variants pv ON pv.id = oi.variant_id
-- WHERE o.placed_at >= NOW() - INTERVAL 30 DAY
-- GROUP BY oi.variant_id, pv.sku, pv.title
-- ORDER BY units_sold DESC
-- LIMIT 10;

-- 3) Customer lifetime value (LTV) top customers
-- SELECT u.id, u.email, COUNT(o.id) AS orders_count, SUM(o.total) AS lifetime_value
-- FROM users u
-- JOIN orders o ON o.user_id = u.id
-- GROUP BY u.id, u.email
-- ORDER BY lifetime_value DESC
-- LIMIT 20;

-- 4) Inventory alerts (low stock)
-- SELECT pv.id AS variant_id, pv.sku, COALESCE(mv.total_available,0) AS total_available
-- FROM product_variants pv
-- LEFT JOIN mv_variant_stock mv ON mv.variant_id = pv.id
-- WHERE COALESCE(mv.total_available,0) < 10
-- ORDER BY total_available ASC;

-- 5) Payment success rate by provider
-- SELECT provider,
--   SUM(CASE WHEN status IN ('captured','authorized') THEN 1 ELSE 0 END) / COUNT(*) AS success_rate,
--   SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) AS failed_count
-- FROM payments
-- GROUP BY provider;

-- ------------------------------
-- Additional stored procedures
-- ------------------------------
DELIMITER $$
DROP PROCEDURE IF EXISTS sp_capture_payment $$
CREATE PROCEDURE sp_capture_payment (
  IN p_order_id CHAR(36),
  IN p_provider_transaction_id VARCHAR(255),
  IN p_status ENUM('initiated','authorized','captured','failed','refunded'),
  IN p_paid_at TIMESTAMP
)
BEGIN
  START TRANSACTION;
  UPDATE payments
  SET provider_transaction_id = p_provider_transaction_id,
      status = p_status,
      paid_at = p_paid_at
  WHERE order_id = p_order_id;

  IF p_status = 'captured' THEN
    UPDATE orders SET status = 'confirmed', updated_at = NOW() WHERE id = p_order_id;
    INSERT INTO audit_logs (id, entity_type, entity_id, action, change, created_at)
    VALUES (UUID(), 'order', p_order_id, 'payment_captured', JSON_OBJECT('txn', p_provider_transaction_id), NOW());
  END IF;
  COMMIT;
END $$
DELIMITER ;

DELIMITER $$
DROP PROCEDURE IF EXISTS sp_adjust_inventory_on_shipment $$
CREATE PROCEDURE sp_adjust_inventory_on_shipment (
  IN p_order_id CHAR(36)
)
BEGIN
  DECLARE done INT DEFAULT 0;
  DECLARE v_variant CHAR(36);
  DECLARE v_qty INT;

  DECLARE cur CURSOR FOR
    SELECT variant_id, SUM(quantity) FROM order_items WHERE order_id = p_order_id GROUP BY variant_id;

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

  START TRANSACTION;
  OPEN cur;
  read_loop: LOOP
    FETCH cur INTO v_variant, v_qty;
    IF done THEN
      LEAVE read_loop;
    END IF;

    -- Decrease qty_available across warehouses (simple approach: reduce reserved then available from warehouses with reserved)
    -- NOTE: For production, maintain reservation records per inventory row
    UPDATE inventory i
    JOIN (
      SELECT id FROM inventory WHERE variant_id = v_variant ORDER BY qty_reserved DESC LIMIT 1
    ) t ON i.id = t.id
    SET i.qty_reserved = GREATEST(i.qty_reserved - v_qty, 0),
        i.qty_available = GREATEST(i.qty_available - v_qty, 0),
        i.last_updated = NOW();

  END LOOP;
  CLOSE cur;
  COMMIT;
END $$
DELIMITER ;

-- ------------------------------
-- Indexing & optimization notes (keep as comments)
-- ------------------------------
-- 1) Use generated columns for JSON attributes to index frequently queried attributes:
-- ALTER TABLE product_variants ADD COLUMN attr_color VARCHAR(100) GENERATED ALWAYS AS (JSON_UNQUOTE(JSON_EXTRACT(attributes,'$.color'))) VIRTUAL;
-- CREATE INDEX idx_variants_attr_color ON product_variants(attr_color);

-- 2) Fulltext on product name & description:
-- ALTER TABLE products ADD FULLTEXT INDEX ft_products_name_desc (name, description);

-- 3) Consider switching CHAR(36) UUIDs to BINARY(16) using UUID_TO_BIN(UUID()) for performance:
-- ALTER TABLE users MODIFY id BINARY(16) NOT NULL PRIMARY KEY;
-- And update INSERT/SELECT to use UUID_TO_BIN()/BIN_TO_UUID()

-- 4) Partition orders/payments for very large datasets by RANGE (TO_DAYS(placed_at)) or by YEAR(placed_at).

-- 5) Use read replicas and offload heavy reporting to replicas.

-- 6) Use ProxySQL or connection pooling in app layer.

-- ------------------------------
-- README / Usage Notes (include in separate README file if desired)
-- ------------------------------
-- 1. Run this file on MySQL 8.0+.
-- 2. If you want compact UUID storage, replace CHAR(36) with BINARY(16) and use UUID_TO_BIN()/BIN_TO_UUID().
-- 3. After initial setup call: CALL sp_refresh_mv_variant_stock();
-- 4. Place orders: CALL sp_place_order(user_id, shipping_addr_id, items_json, 'razorpay', 'INR');
--    Example items_json: '[{"variant_id":"<uuid>","quantity":2}]'
-- 5. Capture payments: CALL sp_capture_payment(order_id, provider_txn_id, 'captured', NOW());
-- 6. On shipment confirmation call: CALL sp_adjust_inventory_on_shipment(order_id);

-- End of file
