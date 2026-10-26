-- Laragon / MySQL 8. Select the intended database before importing.
-- BACK UP FIRST. Deletes all dining_tables and areas records.
-- Existing orders/payments remain; orders.table_id becomes NULL via its FK.
-- Requires the current Savor POS schema (not docs/schema.sql legacy schema).
SET NAMES utf8mb4;

DELIMITER $$
DROP PROCEDURE IF EXISTS replace_restaurant_maps_20261026$$
CREATE PROCEDURE replace_restaurant_maps_20261026()
BEGIN
  DECLARE map_area_id INT;
  DECLARE existing_count INT;
  DECLARE table_count INT;
  DECLARE seat_count INT;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;
  -- Lock affected entities until the replacement completes.
  SELECT COUNT(*) INTO existing_count FROM dining_tables FOR UPDATE;
  SELECT COUNT(*) INTO existing_count FROM areas FOR UPDATE;
  SELECT COUNT(*) INTO existing_count FROM orders
    WHERE table_id IS NOT NULL AND status = 'open' FOR UPDATE;
  IF existing_count > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'STOP: Close all open table orders before replacing tables.';
  END IF;
  SELECT COUNT(*) INTO existing_count FROM areas WHERE code IN ('MAP1','MAP2','MAP3');
  IF existing_count > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'STOP: Map areas already exist. No changes made; do not import twice.';
  END IF;
  DELETE FROM dining_tables;
  DELETE FROM areas;
  DELETE FROM entity_media WHERE entity_type = 'area';

  INSERT INTO areas(code,name,sort) VALUES ('MAP1','Khu bàn ăn',1);
  SET map_area_id = LAST_INSERT_ID();
  INSERT INTO dining_tables(area_id,number,code,name,capacity,status,sort) VALUES
    (map_area_id,1,'B01','Bàn B01',2,'free',1),
    (map_area_id,2,'B02','Bàn B02',2,'free',2),
    (map_area_id,3,'B03','Bàn B03',6,'free',3),
    (map_area_id,4,'B04','Bàn B04',6,'free',4),
    (map_area_id,5,'B05','Bàn B05',6,'free',5),
    (map_area_id,6,'B06','Bàn B06',2,'free',6),
    (map_area_id,7,'B07','Bàn B07',4,'free',7),
    (map_area_id,8,'B08','Bàn B08',6,'free',8),
    (map_area_id,9,'B09','Bàn B09',4,'free',9);

  INSERT INTO areas(code,name,sort) VALUES ('MAP2','Phòng bao',2);
  SET map_area_id = LAST_INSERT_ID();
  INSERT INTO dining_tables(area_id,number,code,name,capacity,status,sort) VALUES
    (map_area_id,1,'P01','Bàn P01',6,'free',1),
    (map_area_id,2,'A01','Bàn A01',6,'free',2),
    (map_area_id,3,'A02','Bàn A02',6,'free',3),
    (map_area_id,4,'A03','Bàn A03',6,'free',4),
    (map_area_id,5,'A04','Bàn A04',6,'free',5),
    (map_area_id,6,'A05','Bàn A05',6,'free',6),
    (map_area_id,7,'A06','Bàn A06',6,'free',7),
    (map_area_id,8,'A07','Bàn A07',6,'free',8),
    (map_area_id,9,'A08','Bàn A08',6,'free',9),
    (map_area_id,10,'A09','Bàn A09',6,'free',10),
    (map_area_id,11,'A10','Bàn A10',6,'free',11);

  INSERT INTO areas(code,name,sort) VALUES ('MAP3','Sân vườn',3);
  SET map_area_id = LAST_INSERT_ID();
  INSERT INTO dining_tables(area_id,number,code,name,capacity,status,sort) VALUES
    (map_area_id,1,'S01','Bàn S01',6,'free',1),
    (map_area_id,2,'S02','Bàn S02',6,'free',2),
    (map_area_id,3,'S03','Bàn S03',6,'free',3),
    (map_area_id,4,'S04','Bàn S04',6,'free',4),
    (map_area_id,5,'S05','Bàn S05',6,'free',5),
    (map_area_id,6,'S06','Bàn S06',6,'free',6),
    (map_area_id,7,'S07','Bàn S07',2,'free',7),
    (map_area_id,8,'S08','Bàn S08',6,'free',8),
    (map_area_id,9,'S09','Bàn S09',4,'free',9),
    (map_area_id,10,'S10','Bàn S10',6,'free',10);

  SELECT COUNT(*), COALESCE(SUM(capacity),0) INTO table_count,seat_count FROM dining_tables;
  IF table_count <> 30 OR seat_count <> 158 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'STOP: Expected 30 tables / 158 seats. Changes rolled back.';
  END IF;
  COMMIT;
END$$
CALL replace_restaurant_maps_20261026()$$
DROP PROCEDURE IF EXISTS replace_restaurant_maps_20261026$$
DELIMITER ;

SELECT a.id,a.code,a.name,COUNT(t.id) AS tables_count,SUM(t.capacity) AS seats
FROM areas a JOIN dining_tables t ON t.area_id=a.id
GROUP BY a.id,a.code,a.name ORDER BY a.sort;
SELECT t.id,t.code,t.capacity,t.status,a.code AS area_code
FROM dining_tables t JOIN areas a ON a.id=t.area_id ORDER BY a.sort,t.sort;
-- Use the returned IDs to configure map links on the target installation.
