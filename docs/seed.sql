-- Seed data for POS Flutter PKA
-- Tables
INSERT INTO tables (name, status) VALUES
  ('Bàn 1', 'available'),
  ('Bàn 2', 'available'),
  ('Bàn 3', 'available'),
  ('Bàn 4', 'available'),
  ('Bàn 5', 'available'),
  ('Bàn 6', 'available'),
  ('Bàn 7', 'available'),
  ('Bàn 8', 'available'),
  ('Bàn 9', 'available'),
  ('Bàn 10', 'available');

-- Menu items
INSERT INTO menu_items (name, category, price, is_active, image_path) VALUES
  ('Cà phê sữa đá', 'Beverage', 25000.00, 1, NULL),
  ('Cà phê đen nóng', 'Beverage', 22000.00, 1, NULL),
  ('Trà đào cam sả', 'Beverage', 32000.00, 1, NULL),
  ('Sinh tố xoài', 'Beverage', 35000.00, 1, NULL),
  ('Nước ép dưa hấu', 'Beverage', 28000.00, 1, NULL),
  ('Bánh mì thịt', 'Food', 30000.00, 1, NULL),
  ('Bánh mì ốp la', 'Food', 27000.00, 1, NULL),
  ('Xôi mặn', 'Food', 25000.00, 1, NULL),
  ('Mì xào bò', 'Food', 45000.00, 1, NULL),
  ('Phở bò tái', 'Food', 48000.00, 1, NULL),
  ('Khoai tây chiên', 'Snack', 20000.00, 1, NULL),
  ('Gà rán', 'Snack', 40000.00, 1, NULL),
  ('Bánh ngọt phô mai', 'Snack', 36000.00, 1, NULL),
  ('Bánh tart trứng', 'Snack', 24000.00, 1, NULL),
  ('Caramen', 'Snack', 23000.00, 1, NULL);
