<?php
// repos/PaymentMethodsRepo.php
require_once __DIR__ . '/../lib/db.php';

class PaymentMethodsRepo {
  public static function list(?string $q = null, ?int $enabled = null): array {
    $sql = "SELECT * FROM payment_methods WHERE 1=1";
    $args = [];
    if ($enabled !== null) {
      $sql .= " AND enabled=?";
      $args[] = $enabled;
    }
    if ($q) {
      $sql .= " AND (name LIKE ? OR code LIKE ?)";
      $args[] = "%$q%";
      $args[] = "%$q%";
    }
    $sql .= " ORDER BY name";
    $s = pdo()->prepare($sql);
    $s->execute($args);
    return $s->fetchAll();
  }

  public static function get(int $id) {
    $s = pdo()->prepare("SELECT * FROM payment_methods WHERE id=?");
    $s->execute([$id]);
    return $s->fetch();
  }

  public static function insert(array $payload): int {
    $sql = "INSERT INTO payment_methods(code, name, enabled) VALUES(?,?,?)";
    pdo()->prepare($sql)->execute([
      $payload['code'],
      $payload['name'],
      isset($payload['enabled']) ? (int)$payload['enabled'] : 1,
    ]);
    return (int)pdo()->lastInsertId();
  }

  public static function update(int $id, array $payload): void {
    $sql = "UPDATE payment_methods SET code=?, name=?, enabled=? WHERE id=?";
    pdo()->prepare($sql)->execute([
      $payload['code'],
      $payload['name'],
      isset($payload['enabled']) ? (int)$payload['enabled'] : 1,
      $id,
    ]);
  }

  public static function delete(int $id): void {
    pdo()->prepare("DELETE FROM payment_methods WHERE id=?")->execute([$id]);
  }

  public static function paymentsForOrder(int $orderId): array {
    $sql = "SELECT p.*, pm.name AS method_name, pm.code AS method_code
            FROM payments p
            JOIN payment_methods pm ON pm.id = p.method_id
            WHERE p.order_id=?
            ORDER BY p.paid_at";
    $s = pdo()->prepare($sql);
    $s->execute([$orderId]);
    return $s->fetchAll();
  }
}
