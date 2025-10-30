<?php
// repos/ShiftsRepo.php
require_once __DIR__ . '/../lib/db.php';

class ShiftsRepo {
  public static function list(array $filters = []): array {
    $sql = "SELECT s.*, u.name AS cashier_name
            FROM shifts s
            JOIN users u ON u.id = s.cashier_id
            WHERE 1=1";
    $args = [];
    if (!empty($filters['cashier_id'])) {
      $sql .= " AND s.cashier_id=?";
      $args[] = (int)$filters['cashier_id'];
    }
    if (!empty($filters['from'])) {
      $sql .= " AND s.opened_at>=?";
      $args[] = $filters['from'];
    }
    if (!empty($filters['to'])) {
      $sql .= " AND (s.closed_at IS NULL OR s.closed_at<=?)";
      $args[] = $filters['to'];
    }
    $sql .= " ORDER BY s.opened_at DESC";
    $s = pdo()->prepare($sql);
    $s->execute($args);
    return $s->fetchAll();
  }

  public static function get(int $id) {
    $s = pdo()->prepare("SELECT s.*, u.name AS cashier_name FROM shifts s JOIN users u ON u.id=s.cashier_id WHERE s.id=?");
    $s->execute([$id]);
    return $s->fetch();
  }

  public static function insert(array $payload): int {
    $sql = "INSERT INTO shifts(cashier_id, opened_at, opening_float, note) VALUES(?,?,?,?)";
    pdo()->prepare($sql)->execute([
      $payload['cashier_id'],
      $payload['opened_at'],
      $payload['opening_float'] ?? 0,
      $payload['note'] ?? null,
    ]);
    return (int)pdo()->lastInsertId();
  }

  public static function close(int $id, array $payload): void {
    $sql = "UPDATE shifts SET closed_at=?, closing_cash=?, note=? WHERE id=?";
    pdo()->prepare($sql)->execute([
      $payload['closed_at'],
      $payload['closing_cash'] ?? 0,
      $payload['note'] ?? null,
      $id,
    ]);
  }

  public static function addMovement(array $payload): int {
    $sql = "INSERT INTO cash_movements(shift_id, type, amount, reason) VALUES(?,?,?,?)";
    pdo()->prepare($sql)->execute([
      $payload['shift_id'],
      $payload['type'],
      $payload['amount'],
      $payload['reason'] ?? null,
    ]);
    return (int)pdo()->lastInsertId();
  }

  public static function movements(int $shiftId): array {
    $sql = "SELECT * FROM cash_movements WHERE shift_id=? ORDER BY created_at";
    $s = pdo()->prepare($sql);
    $s->execute([$shiftId]);
    return $s->fetchAll();
  }

}
