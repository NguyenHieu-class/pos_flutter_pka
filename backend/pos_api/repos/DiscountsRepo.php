<?php
// repos/DiscountsRepo.php
require_once __DIR__ . '/../lib/db.php';

class DiscountsRepo {
  public static function list(array $filters = []): array {
    $sql = "SELECT * FROM discounts WHERE 1=1";
    $args = [];
    if (isset($filters['active'])) {
      $sql .= " AND active=?";
      $args[] = (int)$filters['active'];
    }
    if (!empty($filters['q'])) {
      $sql .= " AND (name LIKE ? OR code LIKE ?)";
      $args[] = "%{$filters['q']}%";
      $args[] = "%{$filters['q']}%";
    }
    $sql .= " ORDER BY name";
    $s = pdo()->prepare($sql);
    $s->execute($args);
    return $s->fetchAll();
  }

  public static function get(int $id) {
    $s = pdo()->prepare("SELECT * FROM discounts WHERE id=?");
    $s->execute([$id]);
    return $s->fetch();
  }

  public static function insert(array $payload): int {
    $sql = "INSERT INTO discounts(code, name, type, value, min_subtotal, active, starts_at, ends_at)
            VALUES(?,?,?,?,?,?,?,?)";
    pdo()->prepare($sql)->execute([
      $payload['code'] ?? null,
      $payload['name'],
      $payload['type'],
      $payload['value'],
      $payload['min_subtotal'] ?? 0,
      isset($payload['active']) ? (int)$payload['active'] : 1,
      $payload['starts_at'] ?? null,
      $payload['ends_at'] ?? null,
    ]);
    return (int)pdo()->lastInsertId();
  }

  public static function update(int $id, array $payload): void {
    $sql = "UPDATE discounts SET code=?, name=?, type=?, value=?, min_subtotal=?, active=?, starts_at=?, ends_at=? WHERE id=?";
    pdo()->prepare($sql)->execute([
      $payload['code'] ?? null,
      $payload['name'],
      $payload['type'],
      $payload['value'],
      $payload['min_subtotal'] ?? 0,
      isset($payload['active']) ? (int)$payload['active'] : 1,
      $payload['starts_at'] ?? null,
      $payload['ends_at'] ?? null,
      $id,
    ]);
  }

  public static function delete(int $id): void {
    pdo()->prepare("DELETE FROM discounts WHERE id=?")->execute([$id]);
  }

  public static function listAvailableForCashier(?float $subtotal = null): array {
    $now = date('Y-m-d H:i:s');
    $sql = "SELECT * FROM discounts WHERE active=1";
    $args = [];
    $sql .= " AND (starts_at IS NULL OR starts_at <= ?)";
    $sql .= " AND (ends_at IS NULL OR ends_at >= ?)";
    $args[] = $now;
    $args[] = $now;
    if ($subtotal !== null) {
      $sql .= " AND (min_subtotal IS NULL OR min_subtotal <= ?)";
      $args[] = $subtotal;
    }
    $sql .= " ORDER BY name";
    $s = pdo()->prepare($sql);
    $s->execute($args);
    return $s->fetchAll();
  }

  public static function findActiveById(int $id) {
    $now = date('Y-m-d H:i:s');
    $sql = "SELECT * FROM discounts WHERE id=? AND active=1";
    $sql .= " AND (starts_at IS NULL OR starts_at <= ?)";
    $sql .= " AND (ends_at IS NULL OR ends_at >= ?)";
    $s = pdo()->prepare($sql);
    $s->execute([$id, $now, $now]);
    return $s->fetch();
  }

  public static function findActiveByCode(string $code) {
    $now = date('Y-m-d H:i:s');
    $sql = "SELECT * FROM discounts WHERE code IS NOT NULL AND UPPER(code)=? AND active=1";
    $sql .= " AND (starts_at IS NULL OR starts_at <= ?)";
    $sql .= " AND (ends_at IS NULL OR ends_at >= ?)";
    $s = pdo()->prepare($sql);
    $s->execute([strtoupper($code), $now, $now]);
    return $s->fetch();
  }

  public static function usageHistory(array $filters = []): array {
    $sql = "SELECT od.*, o.code AS order_code, o.total, o.closed_at
            FROM order_discounts od
            JOIN orders o ON o.id = od.order_id
            WHERE 1=1";
    $args = [];
    if (!empty($filters['discount_id'])) {
      $sql .= " AND od.discount_id=?";
      $args[] = (int)$filters['discount_id'];
    }
    if (!empty($filters['from'])) {
      $sql .= " AND o.closed_at>=?";
      $args[] = $filters['from'];
    }
    if (!empty($filters['to'])) {
      $sql .= " AND o.closed_at<=?";
      $args[] = $filters['to'];
    }
    $sql .= " ORDER BY o.closed_at DESC";
    $s = pdo()->prepare($sql);
    $s->execute($args);
    return $s->fetchAll();
  }
}
