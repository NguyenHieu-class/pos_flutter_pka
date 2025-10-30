<?php
// repos/KitchenRepo.php
require_once __DIR__ . '/../lib/db.php';

class KitchenRepo {
  public static function queue($stationId=null) {
    $sql = "SELECT oi.id order_item_id, oi.order_id, dt.code table_code, a.code area_code,
                   oi.item_name, oi.qty, oi.kitchen_status, ks.name station_name, oi.created_at
            FROM order_items oi
            JOIN orders o ON o.id=oi.order_id AND o.status='open'
            LEFT JOIN dining_tables dt ON dt.id=o.table_id
            LEFT JOIN areas a ON a.id=dt.area_id
            LEFT JOIN kitchen_stations ks ON ks.id=oi.station_id
            WHERE oi.kitchen_status IN ('queued','preparing')";
    $args=[];
    if ($stationId) { $sql.=" AND oi.station_id=?"; $args[]=(int)$stationId; }
    $sql.=" ORDER BY oi.created_at ASC";
    $s = pdo()->prepare($sql); $s->execute($args);
    $rows = $s->fetchAll();

    foreach ($rows as &$r) {
      $m = pdo()->prepare("SELECT option_name, unit_delta, qty FROM order_item_modifiers WHERE order_item_id=? ORDER BY id");
      $m->execute([$r['order_item_id']]);
      $parts=[];
      foreach ($m->fetchAll() as $x) {
        $t = $x['option_name'];
        if ((float)$x['unit_delta'] != 0) $t .= '(+'.number_format($x['unit_delta'],0).')';
        if ((int)$x['qty'] > 1) $t .= ' x'.$x['qty'];
        $parts[] = $t;
      }
      $r['modifiers_text'] = implode('; ', $parts);
    }
    return $rows;
  }

  public static function setItemStatus(int $orderItemId, string $status) {
    pdo()->prepare("UPDATE order_items SET kitchen_status=?, updated_at=NOW() WHERE id=?")
        ->execute([$status, $orderItemId]);
  }
}
