<?php
// repos/ReasonCodesRepo.php
require_once __DIR__ . '/../lib/db.php';

class ReasonCodesRepo {
  public static function list(?string $q = null): array {
    $sql = "SELECT * FROM reason_codes WHERE 1=1";
    $args = [];
    if ($q) {
      $sql .= " AND (code LIKE ? OR description LIKE ?)";
      $args[] = "%$q%";
      $args[] = "%$q%";
    }
    $sql .= " ORDER BY code";
    $s = pdo()->prepare($sql);
    $s->execute($args);
    return $s->fetchAll();
  }

  public static function get(int $id) {
    $s = pdo()->prepare("SELECT * FROM reason_codes WHERE id=?");
    $s->execute([$id]);
    return $s->fetch();
  }

  public static function insert(array $payload): int {
    pdo()->prepare("INSERT INTO reason_codes(code, description) VALUES(?,?)")
        ->execute([$payload['code'], $payload['description']]);
    return (int)pdo()->lastInsertId();
  }

  public static function update(int $id, array $payload): void {
    pdo()->prepare("UPDATE reason_codes SET code=?, description=? WHERE id=?")
        ->execute([$payload['code'], $payload['description'], $id]);
  }

  public static function delete(int $id): void {
    pdo()->prepare("DELETE FROM reason_codes WHERE id=?")->execute([$id]);
  }
}
