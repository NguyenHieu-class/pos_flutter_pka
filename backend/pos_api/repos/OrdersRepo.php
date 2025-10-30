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

  public static function listOrders(?string $status = null): array {
    $pdo = pdo();
    $sql = "SELECT o.id,o.table_id,o.customer_name,o.status,o.opened_at,o.closed_at,o.total,o.subtotal,
                   o.discount_total,o.tax_total,o.service_total,
                   dt.name AS table_name, dt.code AS table_code, dt.status AS table_status,
                   a.name AS area_name, a.code AS area_code,
                   u.name AS opened_by_name,
                   COALESCE(o.total, (
                     SELECT SUM(line_total) FROM order_items oi WHERE oi.order_id = o.id
                   )) AS total_amount
            FROM orders o
            LEFT JOIN dining_tables dt ON dt.id = o.table_id
            LEFT JOIN areas a ON a.id = dt.area_id
            LEFT JOIN users u ON u.id = o.opened_by";
    $params = [];
    if ($status !== null) {
      $sql .= " WHERE o.status = ?";
      $params[] = $status;
    }
    $sql .= " ORDER BY o.opened_at DESC, o.id DESC";

    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    $rows = $stmt->fetchAll();
    foreach ($rows as &$row) {
      if (!isset($row['total']) || $row['total'] === null) {
        $row['total'] = $row['total_amount'];
      }
    }
    unset($row);
    return $rows;
  }
}
