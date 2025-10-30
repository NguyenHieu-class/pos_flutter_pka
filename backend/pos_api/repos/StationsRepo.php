<?php
// repos/StationsRepo.php
require_once __DIR__ . '/../lib/db.php';

class StationsRepo {
  public static function list(?string $q = null): array {
    $sql = "SELECT * FROM kitchen_stations WHERE 1=1";
    $args = [];
    if ($q) {
      $sql .= " AND name LIKE ?";
      $args[] = "%$q%";
    }
    $sql .= " ORDER BY sort, name";
    $s = pdo()->prepare($sql);
    $s->execute($args);
    return $s->fetchAll();
  }

  public static function get(int $id) {
    $s = pdo()->prepare("SELECT * FROM kitchen_stations WHERE id=?");
    $s->execute([$id]);
    return $s->fetch();
  }

  public static function insert(array $payload): int {
    pdo()->prepare("INSERT INTO kitchen_stations(name, icon_path, sort) VALUES(?,?,?)")
        ->execute([$payload['name'], $payload['icon_path'] ?? null, $payload['sort'] ?? 0]);
    return (int)pdo()->lastInsertId();
  }

  public static function update(int $id, array $payload): void {
    pdo()->prepare("UPDATE kitchen_stations SET name=?, icon_path=?, sort=? WHERE id=?")
        ->execute([$payload['name'], $payload['icon_path'] ?? null, $payload['sort'] ?? 0, $id]);
  }

  public static function delete(int $id): void {
    pdo()->prepare("DELETE FROM kitchen_stations WHERE id=?")->execute([$id]);
  }

  public static function updateIconPath(int $id, ?string $path): void {
    pdo()->prepare("UPDATE kitchen_stations SET icon_path=? WHERE id=?")
        ->execute([$path, $id]);
  }
}
