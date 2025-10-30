<?php
// repos/IngredientsRepo.php
require_once __DIR__ . '/../lib/db.php';

class IngredientsRepo {
  public static function list(?string $q = null, ?int $enabled = null): array {
    $sql = "SELECT * FROM ingredients WHERE 1=1";
    $args = [];
    if ($enabled !== null) {
      $sql .= " AND enabled=?";
      $args[] = $enabled;
    }
    if ($q) {
      $sql .= " AND name LIKE ?";
      $args[] = "%$q%";
    }
    $sql .= " ORDER BY name";
    $s = pdo()->prepare($sql);
    $s->execute($args);
    return $s->fetchAll();
  }

  public static function get(int $id) {
    $s = pdo()->prepare("SELECT * FROM ingredients WHERE id=?");
    $s->execute([$id]);
    return $s->fetch();
  }

  public static function insert(array $payload): int {
    $sql = "INSERT INTO ingredients(name, unit, cost, enabled) VALUES(?,?,?,?)";
    pdo()->prepare($sql)->execute([
      $payload['name'],
      $payload['unit'],
      $payload['cost'] ?? 0,
      isset($payload['enabled']) ? (int)$payload['enabled'] : 1,
    ]);
    return (int)pdo()->lastInsertId();
  }

  public static function update(int $id, array $payload): void {
    $sql = "UPDATE ingredients SET name=?, unit=?, cost=?, enabled=? WHERE id=?";
    pdo()->prepare($sql)->execute([
      $payload['name'],
      $payload['unit'],
      $payload['cost'] ?? 0,
      isset($payload['enabled']) ? (int)$payload['enabled'] : 1,
      $id,
    ]);
  }

  public static function delete(int $id): void {
    pdo()->prepare("DELETE FROM ingredients WHERE id=?")->execute([$id]);
  }
}
