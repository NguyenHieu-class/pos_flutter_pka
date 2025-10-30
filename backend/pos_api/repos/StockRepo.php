<?php
// repos/StockRepo.php
require_once __DIR__ . '/../lib/db.php';

class StockRepo {
  public static function addMove(array $payload): int {
    $sql = "INSERT INTO stock_moves(ingredient_id, move_type, qty, ref_entity, ref_id, note)
            VALUES(?,?,?,?,?,?)";
    pdo()->prepare($sql)->execute([
      $payload['ingredient_id'],
      $payload['move_type'],
      $payload['qty'],
      $payload['ref_entity'] ?? null,
      $payload['ref_id'] ?? null,
      $payload['note'] ?? null,
    ]);
    return (int)pdo()->lastInsertId();
  }

  public static function listMoves(array $filters = []): array {
    $sql = "SELECT sm.*, ing.name AS ingredient_name, ing.unit
            FROM stock_moves sm
            JOIN ingredients ing ON ing.id = sm.ingredient_id
            WHERE 1=1";
    $args = [];
    if (!empty($filters['ingredient_id'])) {
      $sql .= " AND sm.ingredient_id=?";
      $args[] = (int)$filters['ingredient_id'];
    }
    if (!empty($filters['from'])) {
      $sql .= " AND sm.created_at>=?";
      $args[] = $filters['from'];
    }
    if (!empty($filters['to'])) {
      $sql .= " AND sm.created_at<=?";
      $args[] = $filters['to'];
    }
    $sql .= " ORDER BY sm.created_at DESC, sm.id DESC";
    $s = pdo()->prepare($sql);
    $s->execute($args);
    return $s->fetchAll();
  }

  public static function currentStock(): array {
    $sql = "SELECT sm.ingredient_id, ing.name, ing.unit,
                   SUM(CASE WHEN sm.move_type='in' THEN sm.qty
                            WHEN sm.move_type='out' THEN -sm.qty
                            ELSE sm.qty END) AS qty
            FROM stock_moves sm
            JOIN ingredients ing ON ing.id = sm.ingredient_id
            GROUP BY sm.ingredient_id, ing.name, ing.unit
            ORDER BY ing.name";
    $s = pdo()->query($sql);
    return $s->fetchAll();
  }

  public static function consumption(array $filters = []): array {
    $sql = "SELECT sm.ingredient_id, ing.name, ing.unit, SUM(sm.qty) AS qty
            FROM stock_moves sm
            JOIN ingredients ing ON ing.id = sm.ingredient_id
            WHERE sm.move_type='out'";
    $args = [];
    if (!empty($filters['from'])) {
      $sql .= " AND sm.created_at>=?";
      $args[] = $filters['from'];
    }
    if (!empty($filters['to'])) {
      $sql .= " AND sm.created_at<=?";
      $args[] = $filters['to'];
    }
    $sql .= " GROUP BY sm.ingredient_id, ing.name, ing.unit
              ORDER BY SUM(sm.qty) DESC";
    $s = pdo()->prepare($sql);
    $s->execute($args);
    return $s->fetchAll();
  }
}
