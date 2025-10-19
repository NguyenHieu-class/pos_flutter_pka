-- Database schema for POS Flutter PKA
CREATE TABLE IF NOT EXISTS tables (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(50) NOT NULL,
  status ENUM('available', 'occupied', 'reserved') NOT NULL DEFAULT 'available',
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS menu_items (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(120) NOT NULL,
  category VARCHAR(50) NULL,
  price DECIMAL(12, 2) NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  image_path VARCHAR(255) NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS orders (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  table_id INT UNSIGNED NOT NULL,
  status ENUM('open', 'paid', 'void') NOT NULL DEFAULT 'open',
  discount_value DECIMAL(12, 2) NOT NULL DEFAULT 0,
  discount_type ENUM('amount', 'percent') NOT NULL DEFAULT 'amount',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  CONSTRAINT fk_orders_table FOREIGN KEY (table_id) REFERENCES tables (id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS order_items (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  order_id BIGINT UNSIGNED NOT NULL,
  item_id INT UNSIGNED NOT NULL,
  qty INT NOT NULL DEFAULT 1,
  note VARCHAR(255) NULL,
  price DECIMAL(12, 2) NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT fk_order_items_order FOREIGN KEY (order_id) REFERENCES orders (id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT fk_order_items_item FOREIGN KEY (item_id) REFERENCES menu_items (id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_tables_status ON tables (status);
CREATE INDEX idx_menu_is_active ON menu_items (is_active);
CREATE INDEX idx_orders_status_created ON orders (status, created_at);
CREATE INDEX idx_order_items_order ON order_items (order_id);
