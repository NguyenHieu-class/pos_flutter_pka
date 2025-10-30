<?php
// controllers/ReportsController.php
require_once __DIR__ . '/../lib/http.php';
require_once __DIR__ . '/../lib/auth.php';
require_once __DIR__ . '/../lib/db.php';
require_once __DIR__ . '/../repos/StockRepo.php';
require_once __DIR__ . '/../repos/ShiftsRepo.php';

class ReportsController {
  public static function revenue() {
    need_role(['admin']);
    $groupBy = query('group_by') ?: 'day';
    $from = query('from');
    $to = query('to');
    $pdo = pdo();
    $select = '';
    $group = '';
    if ($groupBy === 'cashier') {
      $select = 'u.id AS cashier_id, u.name AS cashier_name';
      $group = 'u.id, u.name';
    } elseif ($groupBy === 'area') {
      $select = 'a.id AS area_id, a.code AS area_code, a.name AS area_name';
      $group = 'a.id, a.code, a.name';
    } else {
      $groupBy = 'day';
      $select = "DATE(o.closed_at) AS day";
      $group = 'DATE(o.closed_at)';
    }
    $sql = "SELECT $select,
                   SUM(o.subtotal) AS subtotal,
                   SUM(o.discount_total) AS discount_total,
                   SUM(o.tax_total) AS tax_total,
                   SUM(o.total) AS total
            FROM orders o
            LEFT JOIN users u ON u.id = o.closed_by
            LEFT JOIN dining_tables dt ON dt.id = o.table_id
            LEFT JOIN areas a ON a.id = dt.area_id
            WHERE o.status='closed'";
    $args = [];
    if ($from) { $sql .= ' AND o.closed_at>=?'; $args[] = $from; }
    if ($to)   { $sql .= ' AND o.closed_at<=?'; $args[] = $to; }
    $sql .= " GROUP BY $group ORDER BY MIN(o.closed_at)";
    $stmt = $pdo->prepare($sql);
    $stmt->execute($args);
    $rows = $stmt->fetchAll();
    $data = [];
    foreach ($rows as $row) {
      $entry = [
        'subtotal' => (float)$row['subtotal'],
        'discount_total' => (float)$row['discount_total'],
        'tax_total' => (float)$row['tax_total'],
        'total' => (float)$row['total'],
      ];
      if ($groupBy === 'cashier') {
        $entry['cashier_id'] = $row['cashier_id'] !== null ? (int)$row['cashier_id'] : null;
        $entry['cashier_name'] = $row['cashier_name'];
      } elseif ($groupBy === 'area') {
        $entry['area_id'] = $row['area_id'] !== null ? (int)$row['area_id'] : null;
        $entry['area_code'] = $row['area_code'];
        $entry['area_name'] = $row['area_name'];
      } else {
        $entry['day'] = $row['day'];
      }
      $data[] = $entry;
    }
    json_ok(['group_by' => $groupBy, 'rows' => $data]);
  }

  public static function topItems() {
    need_role(['admin']);
    $metric = query('metric') ?: 'revenue';
    $limit = query('limit') ? (int)query('limit') : 10;
    $from = query('from');
    $to = query('to');
    $order = $metric === 'quantity' ? 'SUM(oi.qty) DESC' : 'SUM(oi.line_total) DESC';
    $pdo = pdo();
    $sql = "SELECT oi.item_id, oi.item_name, SUM(oi.qty) AS quantity, SUM(oi.line_total) AS revenue
            FROM order_items oi
            JOIN orders o ON o.id = oi.order_id AND o.status='closed'";
    $args = [];
    if ($from) { $sql .= ' AND o.closed_at>=?'; $args[] = $from; }
    if ($to)   { $sql .= ' AND o.closed_at<=?'; $args[] = $to; }
    $sql .= " GROUP BY oi.item_id, oi.item_name ORDER BY $order LIMIT $limit";
    $stmt = $pdo->prepare($sql);
    $stmt->execute($args);
    $rows = $stmt->fetchAll();
    $data = array_map(function ($row) {
      return [
        'item_id' => (int)$row['item_id'],
        'item_name' => $row['item_name'],
        'quantity' => (int)$row['quantity'],
        'revenue' => (float)$row['revenue'],
      ];
    }, $rows);
    json_ok(['metric' => $metric, 'rows' => $data]);
  }

  public static function inventory() {
    need_role(['admin']);
    $rows = StockRepo::currentStock();
    $data = array_map(function ($row) {
      return [
        'ingredient_id' => (int)$row['ingredient_id'],
        'ingredient_name' => $row['name'],
        'unit' => $row['unit'],
        'qty' => (float)$row['qty'],
      ];
    }, $rows);
    json_ok($data);
  }

  public static function shiftSummary() {
    need_role(['admin']);
    $rows = ShiftsRepo::list([
      'from' => query('from'),
      'to' => query('to'),
      'cashier_id' => query('cashier_id'),
    ]);
    $pdo = pdo();
    $data = [];
    foreach ($rows as $row) {
      $shiftId = (int)$row['id'];
      $from = $row['opened_at'];
      $to = $row['closed_at'] ?? date('Y-m-d H:i:s');
      $salesStmt = $pdo->prepare("SELECT SUM(CASE WHEN pm.code='cash' THEN p.amount ELSE 0 END) AS cash_sales,
                                         SUM(p.amount) AS total_sales
                                  FROM payments p
                                  JOIN payment_methods pm ON pm.id = p.method_id
                                  JOIN orders o ON o.id = p.order_id
                                  WHERE o.closed_at IS NOT NULL AND o.closed_at BETWEEN ? AND ?");
      $salesStmt->execute([$from, $to]);
      $sales = $salesStmt->fetch() ?: ['cash_sales' => 0, 'total_sales' => 0];
      $moveStmt = $pdo->prepare("SELECT SUM(CASE WHEN type='in' THEN amount ELSE 0 END) AS cash_in,
                                         SUM(CASE WHEN type='out' THEN amount ELSE 0 END) AS cash_out
                                  FROM cash_movements WHERE shift_id=?");
      $moveStmt->execute([$shiftId]);
      $moves = $moveStmt->fetch() ?: ['cash_in' => 0, 'cash_out' => 0];
      $expectedCash = (float)$row['opening_float'] + (float)$sales['cash_sales']
                      + (float)$moves['cash_in'] - (float)$moves['cash_out'];
      $closing = $row['closing_cash'] !== null ? (float)$row['closing_cash'] : null;
      $data[] = [
        'shift' => [
          'id' => $shiftId,
          'cashier_id' => (int)$row['cashier_id'],
          'cashier_name' => $row['cashier_name'],
          'opened_at' => $row['opened_at'],
          'closed_at' => $row['closed_at'],
        ],
        'cash_sales' => (float)$sales['cash_sales'],
        'total_sales' => (float)$sales['total_sales'],
        'cash_in' => (float)$moves['cash_in'],
        'cash_out' => (float)$moves['cash_out'],
        'expected_cash' => $expectedCash,
        'closing_cash' => $closing,
        'difference' => $closing !== null ? $closing - $expectedCash : null,
      ];
    }
    json_ok($data);
  }
}
