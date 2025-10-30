<?php
// repos/OrdersRepo.php
require_once __DIR__ . '/../lib/db.php';

class OrdersRepo {
  public static function findOpenByTable(int $tableId) {
    $s = pdo()->prepare("SELECT id FROM orders WHERE table_id=? AND status='open' LIMIT 1");
    $s->execute([$tableId]); return $s->fetch();
  }
  public static function createOrder(int $tableId, int $uid, ?string $customerName): int {
    $s = pdo()->prepare("INSERT INTO orders(table_id, opened_by, customer_name, status, opened_at) VALUES(?, ?, ?, 'open', NOW())");
    $s->execute([$tableId, $uid, $customerName]);
    return (int)pdo()->lastInsertId();
  }
  public static function getOrderFull(int $orderId) {
    $o = pdo()->prepare("SELECT o.*, dt.code AS table_code, a.code AS area_code, u.name AS opened_by_name
                         FROM orders o
                         LEFT JOIN dining_tables dt ON dt.id=o.table_id
                         LEFT JOIN areas a ON a.id=dt.area_id
                         LEFT JOIN users u ON u.id=o.opened_by
                         WHERE o.id=?");
    $o->execute([$orderId]); $order = $o->fetch();
    if (!$order) return null;

    $i = pdo()->prepare("SELECT oi.*, ks.name AS station_name
                         FROM order_items oi
                         LEFT JOIN kitchen_stations ks ON ks.id=oi.station_id
                         WHERE oi.order_id=? ORDER BY oi.created_at");
    $i->execute([$orderId]); $items = $i->fetchAll();

    $modsMap = [];
    if ($items) {
      $ids = array_column($items, 'id');
      $in = implode(',', array_fill(0, count($ids), '?'));
      $m = pdo()->prepare("SELECT * FROM order_item_modifiers WHERE order_item_id IN ($in) ORDER BY id");
      $m->execute($ids);
      foreach ($m->fetchAll() as $r) $modsMap[$r['order_item_id']][] = $r;
    }
    foreach ($items as &$it) $it['modifiers'] = $modsMap[$it['id']] ?? [];
    $order['items'] = $items;
    return $order;
  }
}
