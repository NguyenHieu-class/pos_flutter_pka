-- =========================================================
-- POS SCHEMA (MySQL 8+) — With Image Support (Legacy + Gallery)
-- =========================================================
CREATE DATABASE IF NOT EXISTS pos
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_general_ci;
USE pos;

SET sql_notes = 0;

-- =========================================================
-- 1) USERS / ROLES / LOGS
-- =========================================================
CREATE TABLE users (
  id              INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Khoá chính người dùng',
  name            VARCHAR(100) NOT NULL COMMENT 'Tên hiển thị',
  username        VARCHAR(60)  NOT NULL UNIQUE COMMENT 'Tên đăng nhập (duy nhất)',
  password_plain  VARCHAR(100) NOT NULL COMMENT 'Mật khẩu dạng plain text (theo yêu cầu)',
  role            ENUM('admin','cashier','kitchen') NOT NULL COMMENT 'Vai trò: admin/quầy/bếp',
  phone           VARCHAR(30) COMMENT 'Số điện thoại',
  email           VARCHAR(120) COMMENT 'Email liên hệ',
  is_active       TINYINT(1) DEFAULT 1 COMMENT 'Trạng thái hoạt động',
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Thời điểm tạo',
  updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Thời điểm cập nhật'
) ENGINE=InnoDB COMMENT='Người dùng hệ thống & vai trò (RBAC cơ bản)';

CREATE TABLE reason_codes (
  id           INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Khoá chính mã lý do',
  code         VARCHAR(30) NOT NULL UNIQUE COMMENT 'Mã lý do (VD: VOID_ITEM)',
  description  VARCHAR(255) NOT NULL COMMENT 'Mô tả chi tiết lý do'
) ENGINE=InnoDB COMMENT='Từ điển lý do huỷ/void phục vụ audit';

CREATE TABLE audit_logs (
  id           BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT 'Khoá chính log',
  user_id      INT COMMENT 'Người thực hiện (nullable)',
  action       VARCHAR(50) NOT NULL COMMENT 'Hành động (VD: CREATE_ITEM)',
  entity       VARCHAR(50) NOT NULL COMMENT 'Thực thể tác động (VD: items)',
  entity_id    BIGINT COMMENT 'ID thực thể',
  payload      JSON COMMENT 'Dữ liệu đính kèm JSON',
  created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Thời điểm log',
  INDEX (entity, entity_id),
  INDEX (user_id),
  CONSTRAINT fk_audit_user FOREIGN KEY (user_id) REFERENCES users(id)
    ON UPDATE RESTRICT ON DELETE SET NULL
) ENGINE=InnoDB COMMENT='Nhật ký thao tác hệ thống cấp kỹ thuật';

-- =========================================================
-- 2) AREAS & TABLES (with image)
-- =========================================================
CREATE TABLE areas (
  id         INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Khoá chính khu vực',
  code       VARCHAR(10) NOT NULL UNIQUE COMMENT 'Mã khu (A/B/C/...)',
  name       VARCHAR(100) NOT NULL COMMENT 'Tên khu vực',
  image_path VARCHAR(255) NULL COMMENT 'Ảnh minh hoạ khu (legacy, file tĩnh trong /uploads/areas/...)',
  sort       INT DEFAULT 0 COMMENT 'Thứ tự hiển thị'
) ENGINE=InnoDB COMMENT='Danh mục khu vực bàn (A, B, C, ...), có ảnh minh hoạ';

CREATE TABLE dining_tables (
  id        INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Khoá chính bàn',
  area_id   INT NOT NULL COMMENT 'Thuộc khu vực nào',
  number    INT NOT NULL COMMENT 'Số thứ tự bàn trong khu (1,2,3,...)',
  code      VARCHAR(20) NOT NULL COMMENT 'Mã bàn hiển thị (VD: A1, B3)',
  name      VARCHAR(100) NOT NULL COMMENT 'Tên bàn (nhãn)',
  capacity  INT DEFAULT 0 COMMENT 'Số ghế của bàn',
  status    ENUM('free','occupied','cleaning') DEFAULT 'free' COMMENT 'Trạng thái: trống/đang dùng/đang dọn',
  sort      INT DEFAULT 0 COMMENT 'Thứ tự hiển thị',
  UNIQUE KEY uk_area_number (area_id, number),
  UNIQUE KEY uk_table_code (code),
  CONSTRAINT fk_table_area FOREIGN KEY (area_id) REFERENCES areas(id)
    ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB COMMENT='Bàn ăn theo khu, hỗ trợ mã A1, A2...';

-- =========================================================
-- 3) MENU / STATIONS / IMAGES (legacy+gallery) & TOPPINGS
-- =========================================================
CREATE TABLE kitchen_stations (
  id        INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Khoá chính trạm bếp',
  name      VARCHAR(100) NOT NULL COMMENT 'Tên trạm (Grill/Fry/Bar...)',
  icon_path VARCHAR(255) NULL COMMENT 'Icon trạm bếp (legacy, /uploads/stations/...)',
  sort      INT DEFAULT 0 COMMENT 'Thứ tự hiển thị'
) ENGINE=InnoDB COMMENT='Trạm bếp để định tuyến món cho bếp (có icon)';

CREATE TABLE categories (
  id          INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Khoá chính danh mục',
  name        VARCHAR(100) NOT NULL COMMENT 'Tên danh mục (Món chính/Đồ uống...)',
  image_path  VARCHAR(255) NULL COMMENT 'Ảnh đại diện danh mục (legacy, /uploads/categories/...)',
  banner_path VARCHAR(255) NULL COMMENT 'Ảnh banner ngang của danh mục (legacy)',
  sort        INT DEFAULT 0 COMMENT 'Thứ tự hiển thị'
) ENGINE=InnoDB COMMENT='Danh mục món ăn/đồ uống (có thumbnail/banner)';

CREATE TABLE items (
  id              INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Khoá chính món',
  category_id     INT NOT NULL COMMENT 'FK danh mục',
  station_id      INT COMMENT 'FK trạm bếp (nullable)',
  sku             VARCHAR(50) COMMENT 'Mã hàng hoá (SKU)',
  name            VARCHAR(150) NOT NULL COMMENT 'Tên món',
  description     VARCHAR(500) COMMENT 'Mô tả',
  price           DECIMAL(12,2) NOT NULL COMMENT 'Giá cơ bản của món',
  tax_rate        DECIMAL(5,2) DEFAULT 0.00 COMMENT 'Thuế % áp cho món (nếu dùng)',
  enabled         TINYINT(1) DEFAULT 1 COMMENT 'Bật/tắt món',
  image_path      VARCHAR(255) NULL COMMENT 'Ảnh chính món (legacy, /uploads/items/...)',
  updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Cập nhật gần nhất',
  FOREIGN KEY (category_id) REFERENCES categories(id)
    ON UPDATE RESTRICT ON DELETE RESTRICT,
  FOREIGN KEY (station_id) REFERENCES kitchen_stations(id)
    ON UPDATE RESTRICT ON DELETE SET NULL,
  INDEX (enabled),
  INDEX (category_id)
) ENGINE=InnoDB COMMENT='Danh mục món ăn (snapshot giá lấy tại thời điểm bán) + ảnh legacy';

CREATE TABLE modifier_groups (
  id           INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Khoá chính nhóm topping',
  name         VARCHAR(100) NOT NULL COMMENT 'Tên nhóm (Topping/Size/Độ cay...)',
  description  VARCHAR(255) COMMENT 'Mô tả nhóm',
  icon_path    VARCHAR(255) NULL COMMENT 'Icon nhóm (legacy, /uploads/modifiers/...)',
  min_select   INT DEFAULT 0 COMMENT 'Phải chọn tối thiểu mấy option',
  max_select   INT DEFAULT 0 COMMENT 'Tối đa; 0 = không giới hạn',
  required     TINYINT(1) DEFAULT 0 COMMENT '1 = bắt buộc chọn',
  sort         INT DEFAULT 0 COMMENT 'Thứ tự hiển thị'
) ENGINE=InnoDB COMMENT='Nhóm tuỳ chọn/topping có thể gán cho nhiều món (có icon)';

CREATE TABLE modifier_options (
  id           INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Khoá chính option topping',
  group_id     INT NOT NULL COMMENT 'FK nhóm topping',
  name         VARCHAR(100) NOT NULL COMMENT 'Tên option (Phô mai/Thêm đường/Size L...)',
  price_delta  DECIMAL(12,2) DEFAULT 0.00 COMMENT 'Giá topping mặc định (cộng thêm vào món)',
  allow_qty    TINYINT(1) DEFAULT 0 COMMENT 'Cho phép chọn nhiều đơn vị của option',
  max_qty      INT DEFAULT 10 COMMENT 'Giới hạn số lượng nếu allow_qty=1',
  is_default   TINYINT(1) DEFAULT 0 COMMENT 'Mặc định tick khi mở popup',
  sort         INT DEFAULT 0 COMMENT 'Thứ tự hiển thị',
  CONSTRAINT fk_modopt_group FOREIGN KEY (group_id)
    REFERENCES modifier_groups(id) ON UPDATE RESTRICT ON DELETE CASCADE,
  INDEX (group_id)
) ENGINE=InnoDB COMMENT='Tuỳ chọn cụ thể (topping) với giá mặc định';

CREATE TABLE item_modifier_groups (
  item_id    INT NOT NULL COMMENT 'FK món',
  group_id   INT NOT NULL COMMENT 'FK nhóm topping',
  PRIMARY KEY (item_id, group_id),
  CONSTRAINT fk_item_group_item FOREIGN KEY (item_id)
    REFERENCES items(id) ON UPDATE RESTRICT ON DELETE CASCADE,
  CONSTRAINT fk_item_group_group FOREIGN KEY (group_id)
    REFERENCES modifier_groups(id) ON UPDATE RESTRICT ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Liên kết món ↔ nhóm topping';

-- =========================================================
-- 4) ORDERS / ORDER ITEMS / KITCHEN FLOW
-- =========================================================
CREATE TABLE orders (
  id             BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT 'Khoá chính đơn hàng',
  code           VARCHAR(30) UNIQUE COMMENT 'Mã đơn hiển thị (tuỳ chọn)',
  table_id       INT COMMENT 'Bàn áp đơn (nullable cho take-away)',
  customer_name  VARCHAR(120) COMMENT 'Tên khách (nếu cần)',
  opened_by      INT NOT NULL COMMENT 'User mở đơn (cashier)',
  closed_by      INT COMMENT 'User đóng đơn',
  status         ENUM('open','closed','cancelled') DEFAULT 'open' COMMENT 'Trạng thái đơn',
  subtotal       DECIMAL(12,2) DEFAULT 0.00 COMMENT 'Tổng trước giảm/thuế',
  discount_total DECIMAL(12,2) DEFAULT 0.00 COMMENT 'Tổng giảm giá',
  tax_total      DECIMAL(12,2) DEFAULT 0.00 COMMENT 'Tổng thuế',
  service_total  DECIMAL(12,2) DEFAULT 0.00 COMMENT 'Phí phục vụ (nếu có)',
  total          DECIMAL(12,2) DEFAULT 0.00 COMMENT 'Tổng thanh toán cuối',
  opened_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Thời điểm mở đơn',
  closed_at      TIMESTAMP NULL COMMENT 'Thời điểm đóng đơn',
  note           VARCHAR(255) COMMENT 'Ghi chú',
  FOREIGN KEY (table_id) REFERENCES dining_tables(id)
    ON UPDATE RESTRICT ON DELETE SET NULL,
  FOREIGN KEY (opened_by) REFERENCES users(id)
    ON UPDATE RESTRICT ON DELETE RESTRICT,
  FOREIGN KEY (closed_by) REFERENCES users(id)
    ON UPDATE RESTRICT ON DELETE SET NULL,
  INDEX (status),
  INDEX (opened_at)
) ENGINE=InnoDB COMMENT='Đơn hàng tại bàn (mỗi bàn chỉ có 1 đơn open)';

CREATE TABLE order_items (
  id               BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT 'Khoá chính dòng món',
  order_id         BIGINT NOT NULL COMMENT 'FK đơn hàng',
  item_id          INT    NOT NULL COMMENT 'FK món gốc',
  item_name        VARCHAR(150) NOT NULL COMMENT 'Snapshot tên món tại thời điểm đặt',
  station_id       INT COMMENT 'Trạm bếp định tuyến',
  qty              INT NOT NULL COMMENT 'Số lượng món',
  unit_price       DECIMAL(12,2) NOT NULL COMMENT 'Snapshot giá món tại thời điểm đặt',
  discount_amount  DECIMAL(12,2) DEFAULT 0.00 COMMENT 'Giảm trực tiếp cho dòng',
  tax_rate         DECIMAL(5,2)  DEFAULT 0.00 COMMENT 'Thuế % (nếu tính theo dòng)',
  line_total       DECIMAL(12,2) NOT NULL COMMENT 'Thành tiền dòng (đã cộng topping)',
  note             VARCHAR(255) COMMENT 'Ghi chú riêng dòng',
  course_no        INT DEFAULT 1 COMMENT 'Số course/đợt',
  priority         INT DEFAULT 0 COMMENT 'Ưu tiên trong bếp',
  kitchen_status   ENUM('queued','preparing','ready','served','cancelled') DEFAULT 'queued' COMMENT 'Trạng thái bếp cho dòng món',
  created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Thời điểm tạo dòng',
  updated_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Cập nhật dòng',
  FOREIGN KEY (order_id) REFERENCES orders(id)
    ON UPDATE RESTRICT ON DELETE CASCADE,
  FOREIGN KEY (item_id)  REFERENCES items(id)
    ON UPDATE RESTRICT ON DELETE RESTRICT,
  FOREIGN KEY (station_id) REFERENCES kitchen_stations(id)
    ON UPDATE RESTRICT ON DELETE SET NULL,
  INDEX (order_id),
  INDEX (kitchen_status, created_at),
  INDEX (station_id, kitchen_status)
) ENGINE=InnoDB COMMENT='Chi tiết món trong đơn + trạng thái bếp';

CREATE TABLE order_item_modifiers (
  id                 BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT 'Khoá chính topping của dòng',
  order_item_id      BIGINT NOT NULL COMMENT 'FK dòng món',
  option_id          INT    NOT NULL COMMENT 'FK option gốc',
  option_name        VARCHAR(100) NOT NULL COMMENT 'Snapshot tên option',
  unit_delta         DECIMAL(12,2) NOT NULL COMMENT 'Snapshot giá topping/1 suất',
  qty                INT NOT NULL DEFAULT 1 COMMENT 'Số lượng của option (nếu cho phép)',
  FOREIGN KEY (order_item_id) REFERENCES order_items(id)
    ON UPDATE RESTRICT ON DELETE CASCADE,
  FOREIGN KEY (option_id) REFERENCES modifier_options(id)
    ON UPDATE RESTRICT ON DELETE RESTRICT,
  INDEX (order_item_id)
) ENGINE=InnoDB COMMENT='Topping đã chọn (snapshot) cho từng dòng món';

CREATE TABLE kitchen_tickets (
  id          BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT 'Khoá chính phiếu bếp',
  order_id    BIGINT NOT NULL COMMENT 'FK đơn hàng',
  ticket_no   INT NOT NULL COMMENT 'Số phiếu trong phạm vi 1 đơn',
  status      ENUM('open','ready','served','cancelled') DEFAULT 'open' COMMENT 'Trạng thái phiếu',
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Thời điểm lập phiếu',
  FOREIGN KEY (order_id) REFERENCES orders(id)
    ON UPDATE RESTRICT ON DELETE CASCADE,
  UNIQUE KEY uk_ticket_per_order (order_id, ticket_no)
) ENGINE=InnoDB COMMENT='Phiếu gom món đẩy bếp (tuỳ chọn sử dụng)';

CREATE TABLE kitchen_ticket_items (
  ticket_id     BIGINT NOT NULL COMMENT 'FK phiếu bếp',
  order_item_id BIGINT NOT NULL COMMENT 'FK dòng món',
  PRIMARY KEY (ticket_id, order_item_id),
  FOREIGN KEY (ticket_id) REFERENCES kitchen_tickets(id)
    ON UPDATE RESTRICT ON DELETE CASCADE,
  FOREIGN KEY (order_item_id) REFERENCES order_items(id)
    ON UPDATE RESTRICT ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Ánh xạ dòng món vào phiếu bếp';

CREATE TABLE discounts (
  id            INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Khoá chính khuyến mại',
  code          VARCHAR(50) UNIQUE COMMENT 'Mã giảm giá',
  name          VARCHAR(120) NOT NULL COMMENT 'Tên chương trình',
  type          ENUM('percent','amount') NOT NULL COMMENT 'Kiểu: % hay số tiền',
  value         DECIMAL(12,2) NOT NULL COMMENT 'Giá trị giảm',
  min_subtotal  DECIMAL(12,2) DEFAULT 0.00 COMMENT 'Điều kiện tối thiểu',
  active        TINYINT(1) DEFAULT 1 COMMENT 'Bật/tắt',
  starts_at     DATETIME NULL COMMENT 'Hiệu lực từ',
  ends_at       DATETIME NULL COMMENT 'Hiệu lực đến'
) ENGINE=InnoDB COMMENT='Chương trình giảm giá';

CREATE TABLE order_discounts (
  id          BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT 'Khoá chính giảm áp vào đơn',
  order_id    BIGINT NOT NULL COMMENT 'FK đơn',
  discount_id INT COMMENT 'FK chương trình (nullable khi giảm tay)',
  code        VARCHAR(50) COMMENT 'Mã giảm/snapshot',
  name        VARCHAR(120) NOT NULL COMMENT 'Tên giảm/snapshot',
  type        ENUM('percent','amount') NOT NULL COMMENT 'Kiểu',
  value       DECIMAL(12,2) NOT NULL COMMENT 'Giá trị',
  amount      DECIMAL(12,2) NOT NULL COMMENT 'Số tiền giảm thực',
  FOREIGN KEY (order_id)   REFERENCES orders(id)
    ON UPDATE RESTRICT ON DELETE CASCADE,
  FOREIGN KEY (discount_id) REFERENCES discounts(id)
    ON UPDATE RESTRICT ON DELETE SET NULL,
  INDEX (order_id)
) ENGINE=InnoDB COMMENT='Các giảm giá đã áp dụng cho đơn (snapshot)';

-- =========================================================
-- 5) PAYMENTS / SHIFTS / CASHBOX
-- =========================================================
CREATE TABLE payment_methods (
  id        INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Khoá chính phương thức thanh toán',
  code      VARCHAR(30) UNIQUE COMMENT 'Mã phương thức (cash/card/...)',
  name      VARCHAR(100) NOT NULL COMMENT 'Tên phương thức',
  enabled   TINYINT(1) DEFAULT 1 COMMENT 'Bật/tắt'
) ENGINE=InnoDB COMMENT='Từ điển phương thức thanh toán';

CREATE TABLE payments (
  id          BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT 'Khoá chính phiếu thanh toán',
  order_id    BIGINT NOT NULL COMMENT 'FK đơn hàng',
  method_id   INT    NOT NULL COMMENT 'FK phương thức/tài khoản',
  amount      DECIMAL(12,2) NOT NULL COMMENT 'Số tiền đã thanh toán',
  paid_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Thời điểm thanh toán',
  ref_no      VARCHAR(100) COMMENT 'Số tham chiếu (nếu có)',
  FOREIGN KEY (order_id) REFERENCES orders(id)
    ON UPDATE RESTRICT ON DELETE CASCADE,
  FOREIGN KEY (method_id) REFERENCES payment_methods(id)
    ON UPDATE RESTRICT ON DELETE RESTRICT,
  INDEX (order_id)
) ENGINE=InnoDB COMMENT='Các khoản thanh toán cho đơn';

CREATE TABLE shifts (
  id            INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Khoá chính ca làm',
  cashier_id    INT NOT NULL COMMENT 'Nhân viên mở ca',
  opened_at     DATETIME NOT NULL COMMENT 'Thời điểm mở ca',
  closed_at     DATETIME NULL COMMENT 'Thời điểm đóng ca',
  opening_float DECIMAL(12,2) DEFAULT 0.00 COMMENT 'Tiền đầu ca',
  closing_cash  DECIMAL(12,2) DEFAULT 0.00 COMMENT 'Tiền mặt cuối ca',
  note          VARCHAR(255) COMMENT 'Ghi chú',
  FOREIGN KEY (cashier_id) REFERENCES users(id)
    ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB COMMENT='Ca làm việc của thu ngân';

CREATE TABLE cash_movements (
  id         BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT 'Khoá chính dòng quỹ',
  shift_id   INT NOT NULL COMMENT 'FK ca làm',
  type       ENUM('in','out') NOT NULL COMMENT 'Thu/chi',
  amount     DECIMAL(12,2) NOT NULL COMMENT 'Số tiền',
  reason     VARCHAR(200) COMMENT 'Lý do',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Thời điểm ghi',
  FOREIGN KEY (shift_id) REFERENCES shifts(id)
    ON UPDATE RESTRICT ON DELETE CASCADE,
  INDEX (shift_id)
) ENGINE=InnoDB COMMENT='Sổ quỹ ca làm (thu/chi ngoài hoá đơn)';

-- =========================================================
-- 6) CANCEL / VOID / ACTIVITY
-- =========================================================
CREATE TABLE order_cancellations (
  id           BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT 'Khoá chính huỷ đơn',
  order_id     BIGINT NOT NULL COMMENT 'FK đơn',
  user_id      INT    NOT NULL COMMENT 'Người huỷ',
  reason_id    INT COMMENT 'Lý do (nullable)',
  note         VARCHAR(255) COMMENT 'Ghi chú',
  created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Thời điểm',
  FOREIGN KEY (order_id) REFERENCES orders(id)
    ON UPDATE RESTRICT ON DELETE CASCADE,
  FOREIGN KEY (user_id)  REFERENCES users(id)
    ON UPDATE RESTRICT ON DELETE RESTRICT,
  FOREIGN KEY (reason_id) REFERENCES reason_codes(id)
    ON UPDATE RESTRICT ON DELETE SET NULL
) ENGINE=InnoDB COMMENT='Lưu lần huỷ đơn (audit)';

CREATE TABLE order_item_voids (
  id            BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT 'Khoá chính void món',
  order_item_id BIGINT NOT NULL COMMENT 'FK dòng món',
  user_id       INT    NOT NULL COMMENT 'Người void',
  reason_id     INT COMMENT 'Lý do',
  qty           INT NOT NULL COMMENT 'Số lượng void',
  note          VARCHAR(255) COMMENT 'Ghi chú',
  created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Thời điểm',
  FOREIGN KEY (order_item_id) REFERENCES order_items(id)
    ON UPDATE RESTRICT ON DELETE CASCADE,
  FOREIGN KEY (user_id)       REFERENCES users(id)
    ON UPDATE RESTRICT ON DELETE RESTRICT,
  FOREIGN KEY (reason_id)     REFERENCES reason_codes(id)
    ON UPDATE RESTRICT ON DELETE SET NULL
) ENGINE=InnoDB COMMENT='Lưu lần huỷ/void từng dòng món (audit)';

CREATE TABLE activity_logs (
  id          BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT 'Khoá chính log hoạt động',
  user_id     INT COMMENT 'Người thực hiện (nullable)',
  scope       ENUM('kitchen','cashier','admin') NOT NULL COMMENT 'Phạm vi: bếp/quầy/admin',
  message     VARCHAR(255) NOT NULL COMMENT 'Nội dung log',
  ref_entity  VARCHAR(50) COMMENT 'Thực thể liên quan',
  ref_id      BIGINT COMMENT 'ID thực thể',
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Thời điểm',
  INDEX (scope, created_at),
  FOREIGN KEY (user_id) REFERENCES users(id)
    ON UPDATE RESTRICT ON DELETE SET NULL
) ENGINE=InnoDB COMMENT='Log hoạt động nghiệp vụ (cấp người dùng)';

-- =========================================================
-- 7) (OPTIONAL) INGREDIENTS / RECIPES / STOCK
-- =========================================================
CREATE TABLE ingredients (
  id          INT AUTO_INCREMENT PRIMARY KEY COMMENT 'Khoá chính nguyên liệu',
  name        VARCHAR(120) NOT NULL COMMENT 'Tên nguyên liệu',
  unit        VARCHAR(20)  NOT NULL COMMENT 'Đơn vị (g/kg/ml/...)',
  cost        DECIMAL(12,4) DEFAULT 0.0000 COMMENT 'Giá vốn theo đơn vị',
  enabled     TINYINT(1) DEFAULT 1 COMMENT 'Bật/tắt'
) ENGINE=InnoDB COMMENT='Nguyên liệu (nếu quản lý kho/định lượng)';

CREATE TABLE item_recipes (
  item_id       INT NOT NULL COMMENT 'FK món',
  ingredient_id INT NOT NULL COMMENT 'FK nguyên liệu',
  qty           DECIMAL(12,4) NOT NULL COMMENT 'Định lượng/1 suất',
  PRIMARY KEY (item_id, ingredient_id),
  FOREIGN KEY (item_id)       REFERENCES items(id)
    ON UPDATE RESTRICT ON DELETE CASCADE,
  FOREIGN KEY (ingredient_id) REFERENCES ingredients(id)
    ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB COMMENT='Công thức món (BOM)';

CREATE TABLE stock_moves (
  id            BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT 'Khoá chính dịch chuyển kho',
  ingredient_id INT NOT NULL COMMENT 'FK nguyên liệu',
  move_type     ENUM('in','out','adjust') NOT NULL COMMENT 'Loại dịch chuyển',
  qty           DECIMAL(12,4) NOT NULL COMMENT 'Số lượng dịch chuyển',
  ref_entity    VARCHAR(50) COMMENT 'Nguồn tham chiếu (VD: order_item)',
  ref_id        BIGINT COMMENT 'ID tham chiếu',
  note          VARCHAR(255) COMMENT 'Ghi chú',
  created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Thời điểm',
  FOREIGN KEY (ingredient_id) REFERENCES ingredients(id)
    ON UPDATE RESTRICT ON DELETE RESTRICT,
  INDEX (ingredient_id, created_at)
) ENGINE=InnoDB COMMENT='Lịch sử nhập/xuất/điều chỉnh kho';

-- =========================================================
-- 8) RECEIPTS SNAPSHOT (ADMIN ONLY)
-- =========================================================
CREATE TABLE receipts (
  id              BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT 'Khoá chính hoá đơn snapshot',
  order_id        BIGINT NOT NULL COMMENT 'FK đơn nguồn',
  receipt_no      VARCHAR(50) UNIQUE COMMENT 'Số hoá đơn in',
  table_code      VARCHAR(20) COMMENT 'Mã bàn (A1/B2...) tại thời điểm đóng',
  area_code       VARCHAR(10) COMMENT 'Mã khu tại thời điểm đóng',
  cashier_id      INT NOT NULL COMMENT 'Nhân viên thu ngân',
  cashier_name    VARCHAR(100) NOT NULL COMMENT 'Snapshot tên thu ngân',
  customer_name   VARCHAR(120) COMMENT 'Tên khách (nếu có)',
  subtotal        DECIMAL(12,2) NOT NULL COMMENT 'Tổng trước giảm/thuế (snapshot)',
  discount_total  DECIMAL(12,2) NOT NULL COMMENT 'Tổng giảm (snapshot)',
  tax_total       DECIMAL(12,2) NOT NULL COMMENT 'Tổng thuế (snapshot)',
  service_total   DECIMAL(12,2) NOT NULL COMMENT 'Phí phục vụ (snapshot)',
  total           DECIMAL(12,2) NOT NULL COMMENT 'Tổng thanh toán (snapshot)',
  paid_methods    VARCHAR(200) COMMENT 'Chuỗi tóm tắt phương thức thanh toán',
  paid_at         DATETIME NOT NULL COMMENT 'Thời điểm thanh toán',
  note            VARCHAR(255) COMMENT 'Ghi chú hoá đơn',
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Thời điểm ghi snapshot',
  FOREIGN KEY (order_id) REFERENCES orders(id)
    ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB COMMENT='Bản sao hoá đơn sau checkout (phục vụ báo cáo, chỉ admin)';

CREATE TABLE receipt_items (
  id             BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT 'Khoá chính dòng hoá đơn',
  receipt_id     BIGINT NOT NULL COMMENT 'FK hoá đơn snapshot',
  item_name      VARCHAR(150) NOT NULL COMMENT 'Snapshot tên món',
  qty            INT NOT NULL COMMENT 'Số lượng',
  unit_price     DECIMAL(12,2) NOT NULL COMMENT 'Đơn giá snapshot',
  modifiers_text VARCHAR(255) COMMENT 'Chuỗi mô tả topping đã chọn',
  line_total     DECIMAL(12,2) NOT NULL COMMENT 'Thành tiền dòng',
  FOREIGN KEY (receipt_id) REFERENCES receipts(id)
    ON UPDATE RESTRICT ON DELETE CASCADE,
  INDEX (receipt_id)
) ENGINE=InnoDB COMMENT='Chi tiết các món trong hoá đơn snapshot';

-- =========================================================
-- 9) MEDIA LIBRARY (GALLERY) — NEW
-- =========================================================
CREATE TABLE media_files (
  id         BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT 'Khoá chính media',
  path       VARCHAR(255) NOT NULL UNIQUE COMMENT 'Đường dẫn tương đối (vd: uploads/items/abc.jpg)',
  alt_text   VARCHAR(150) NULL COMMENT 'Mô tả/ngôn ngữ thay thế (SEO/Accessibility)',
  mime_type  VARCHAR(100) NULL COMMENT 'image/jpeg, image/png...',
  bytes      INT UNSIGNED NULL COMMENT 'Kích thước file (bytes)',
  width      INT NULL COMMENT 'Chiều rộng px (nếu có)',
  height     INT NULL COMMENT 'Chiều cao px (nếu có)',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Thời điểm lưu'
) ENGINE=InnoDB COMMENT='Kho media chuẩn hoá (ảnh/file)';

CREATE TABLE entity_media (
  id           BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT 'Khoá chính liên kết media',
  entity_type  ENUM('item','category','area','modifier_group','kitchen_station') NOT NULL COMMENT 'Loại thực thể',
  entity_id    BIGINT NOT NULL COMMENT 'Khoá thực thể',
  media_id     BIGINT NOT NULL COMMENT 'FK media_files.id',
  role         ENUM('primary','thumbnail','banner','gallery') NOT NULL DEFAULT 'gallery' COMMENT 'Vai trò ảnh',
  sort         INT DEFAULT 0 COMMENT 'Thứ tự hiển thị',
  created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Thời điểm gán',
  UNIQUE KEY uk_entity_role_primary (entity_type, entity_id, role, sort),
  INDEX idx_entity (entity_type, entity_id),
  CONSTRAINT fk_entity_media_file FOREIGN KEY (media_id) REFERENCES media_files(id)
    ON UPDATE RESTRICT ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Gán ảnh theo vai trò (primary/thumb/banner/gallery) cho các thực thể';

SET sql_notes = 1;
