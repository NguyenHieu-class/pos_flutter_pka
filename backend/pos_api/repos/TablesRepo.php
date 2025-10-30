<?php
// repos/TablesRepo.php
require_once __DIR__ . '/../lib/db.php';

class TablesRepo {
  public static function areas() {
    return pdo()->query("SELECT * FROM areas ORDER BY sort, id")->fetchAll();
  }

  public static function insertArea(array $b): int {
    $sql = "INSERT INTO areas(code, name, sort, image_path) VALUES(?,?,?,?)";
    pdo()->prepare($sql)->execute([
      $b['code'] ?? null,
      $b['name'],
      $b['sort'] ?? null,
      $b['image_path'] ?? null,
    ]);
    return (int)pdo()->lastInsertId();
  }

  public static function updateArea(int $id, array $b) {
    $sql = "UPDATE areas SET code=?, name=?, sort=?, image_path=? WHERE id=?";
    pdo()->prepare($sql)->execute([
      $b['code'] ?? null,
      $b['name'],
      $b['sort'] ?? null,
      $b['image_path'] ?? null,
      $id,
    ]);
  }

  public static function deleteArea(int $id) {
    pdo()->prepare("DELETE FROM areas WHERE id=?")->execute([$id]);
  }

  public static function tables($areaId = null, $status = null) {
    $sql = "SELECT dt.*, a.code AS area_code, a.name AS area_name"
          . " FROM dining_tables dt"
          . " JOIN areas a ON a.id=dt.area_id"
          . " WHERE 1=1";
    $args = [];
    if ($areaId) { $sql .= " AND dt.area_id=?"; $args[] = (int)$areaId; }
    if ($status) { $sql .= " AND dt.status=?"; $args[] = $status; }
    $sql .= " ORDER BY a.sort, dt.number";
    $stmt = pdo()->prepare($sql);
    $stmt->execute($args);
    return $stmt->fetchAll();
  }

  public static function setStatus(int $tableId, string $status) {
    pdo()->prepare("UPDATE dining_tables SET status=? WHERE id=?")->execute([$status, $tableId]);
  }

  public static function insertTable(array $b): int {
    $sql = "INSERT INTO dining_tables(area_id, code, name, number, capacity, status) VALUES(?,?,?,?,?,?)";
    pdo()->prepare($sql)->execute([
      $b['area_id'],
      $b['code'] ?? null,
      $b['name'],
      $b['number'] ?? null,
      $b['capacity'] ?? null,
      $b['status'] ?? 'free',
    ]);
    return (int)pdo()->lastInsertId();
  }

  public static function updateTable(int $id, array $b) {
    $sql = "UPDATE dining_tables SET area_id=?, code=?, name=?, number=?, capacity=?, status=? WHERE id=?";
    pdo()->prepare($sql)->execute([
      $b['area_id'],
      $b['code'] ?? null,
      $b['name'],
      $b['number'] ?? null,
      $b['capacity'] ?? null,
      $b['status'] ?? 'free',
      $id,
    ]);
  }

  public static function deleteTable(int $id) {
    pdo()->prepare("DELETE FROM dining_tables WHERE id=?")->execute([$id]);
  }

  public static function updateAreaImage(int $id, ?string $path) {
    pdo()->prepare("UPDATE areas SET image_path=? WHERE id=?")->execute([$path, $id]);
  }
}

