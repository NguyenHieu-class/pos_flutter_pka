<?php
// repos/KitchenRepo.php
require_once __DIR__ . '/../lib/db.php';

class KitchenRepo {
  public static function queue(array $filters = []) {
    return self::list($filters, false);
  }

  public static function history(array $filters = []) {
    return self::list($filters, true);
  }

  private static function list(array $filters, bool $history) {
    $sql = "SELECT oi.id order_item_id, oi.order_id, dt.code table_code, dt.name table_name,
                   a.code area_code, a.name area_name, oi.item_name, oi.qty, oi.kitchen_status,
                   oi.note, oi.kitchen_cancel_reason, oi.created_at, oi.updated_at,
                   ks.id station_id, ks.name station_name, c.id category_id, c.name category_name
            FROM order_items oi
            JOIN orders o ON o.id=oi.order_id";
    if (!$history) {
      $sql .= " AND o.status='open'";
    }
    $sql .= " LEFT JOIN dining_tables dt ON dt.id=o.table_id
            LEFT JOIN areas a ON a.id=dt.area_id
            LEFT JOIN items i ON i.id=oi.item_id
            LEFT JOIN categories c ON c.id=i.category_id
            LEFT JOIN kitchen_stations ks ON ks.id=oi.station_id
            WHERE 1=1";

    $args = [];

    $statuses = $filters['statuses'] ?? null;
    if (is_array($statuses) && count($statuses) > 0) {
      $placeholders = implode(',', array_fill(0, count($statuses), '?'));
      $sql .= " AND oi.kitchen_status IN ($placeholders)";
      foreach ($statuses as $st) { $args[] = $st; }
    } else if (!$history) {
      $sql .= " AND oi.kitchen_status IN ('queued','preparing','ready')";
    }

    if (!empty($filters['station_id'])) {
      $sql .= " AND oi.station_id=?";
      $args[] = (int)$filters['station_id'];
    }
    if (!empty($filters['area_code'])) {
      $sql .= " AND a.code=?";
      $args[] = $filters['area_code'];
    }
    if (!empty($filters['table_code'])) {
      $sql .= " AND dt.code=?";
      $args[] = $filters['table_code'];
    }
    if (!empty($filters['category_id'])) {
      $sql .= " AND c.id=?";
      $args[] = (int)$filters['category_id'];
    }

    if ($history) {
      $sql .= " ORDER BY oi.updated_at DESC";
    } else {
      $sql .= " ORDER BY oi.created_at ASC";
    }

    $s = pdo()->prepare($sql);
    $s->execute($args);
    $rows = $s->fetchAll();

    foreach ($rows as &$r) {
      $m = pdo()->prepare("SELECT option_name, unit_delta, qty FROM order_item_modifiers WHERE order_item_id=? ORDER BY id");
      $m->execute([$r['order_item_id']]);
      $parts = [];
      foreach ($m->fetchAll() as $x) {
        $t = $x['option_name'];
        if ((float)$x['unit_delta'] != 0) $t .= '(+'.number_format($x['unit_delta'], 0).')';
        if ((int)$x['qty'] > 1) $t .= ' x'.$x['qty'];
        $parts[] = $t;
      }
      $r['modifiers_text'] = implode('; ', $parts);
    }
    return $rows;
  }

  public static function setItemStatus(int $orderItemId, string $status, ?string $reason = null) {
    $sql = "UPDATE order_items SET kitchen_status=?, kitchen_cancel_reason=?, updated_at=NOW() WHERE id=?";
    if ($status !== 'cancelled') {
      $reason = null;
    }
    pdo()->prepare($sql)->execute([$status, $reason, $orderItemId]);
  }
}
