<?php
// controllers/ShiftsController.php
require_once __DIR__ . '/../lib/http.php';
require_once __DIR__ . '/../lib/auth.php';
require_once __DIR__ . '/../repos/ShiftsRepo.php';
require_once __DIR__ . '/../lib/db.php';

class ShiftsController {
  private static function sanitize(array $row): array {
    return [
      'id' => (int)$row['id'],
      'cashier_id' => (int)$row['cashier_id'],
      'cashier_name' => $row['cashier_name'],
      'opened_at' => $row['opened_at'],
      'closed_at' => $row['closed_at'],
      'opening_float' => (float)$row['opening_float'],
      'closing_cash' => $row['closing_cash'] !== null ? (float)$row['closing_cash'] : null,
      'note' => $row['note'],
    ];
  }

  public static function list() {
    need_role(['admin']);
    $rows = ShiftsRepo::list([
      'cashier_id' => query('cashier_id'),
      'from' => query('from'),
      'to' => query('to'),
    ]);
    json_ok(array_map(fn($row) => self::sanitize($row), $rows));
  }

  public static function create() {
    need_role(['admin']);
    $b = input_json();
    require_fields($b, ['cashier_id', 'opened_at']);
    $payload = [
      'cashier_id' => (int)$b['cashier_id'],
      'opened_at' => $b['opened_at'],
      'opening_float' => isset($b['opening_float']) ? (float)$b['opening_float'] : 0,
      'note' => $b['note'] ?? null,
    ];
    $id = ShiftsRepo::insert($payload);
    $row = ShiftsRepo::get($id);
    json_ok(self::sanitize($row), 201);
  }

  public static function close($id) {
    need_role(['admin']);
    $b = input_json();
    require_fields($b, ['closed_at']);
    $payload = [
      'closed_at' => $b['closed_at'],
      'closing_cash' => isset($b['closing_cash']) ? (float)$b['closing_cash'] : 0,
      'note' => $b['note'] ?? null,
    ];
    ShiftsRepo::close((int)$id, $payload);
    $row = ShiftsRepo::get((int)$id);
    if (!$row) json_err('NOT_FOUND', 'Shift not found', [], 404);
    json_ok(self::sanitize($row));
  }

  public static function movements($shiftId) {
    need_role(['admin']);
    $rows = ShiftsRepo::movements((int)$shiftId);
    $data = array_map(function ($row) {
      return [
        'id' => (int)$row['id'],
        'shift_id' => (int)$row['shift_id'],
        'type' => $row['type'],
        'amount' => (float)$row['amount'],
        'reason' => $row['reason'],
        'created_at' => $row['created_at'],
      ];
    }, $rows);
    json_ok($data);
  }

  public static function addMovement($shiftId) {
    need_role(['admin']);
    $b = input_json();
    require_fields($b, ['type', 'amount']);
    if (!in_array($b['type'], ['in', 'out'], true)) {
      json_err('VALIDATION_FAILED', 'Loại giao dịch không hợp lệ', ['field' => 'type'], 422);
    }
    $amount = (float)$b['amount'];
    if ($amount <= 0) json_err('VALIDATION_FAILED', 'Số tiền phải lớn hơn 0', ['field' => 'amount'], 422);
    $payload = [
      'shift_id' => (int)$shiftId,
      'type' => $b['type'],
      'amount' => $amount,
      'reason' => $b['reason'] ?? null,
    ];
    $id = ShiftsRepo::addMovement($payload);
    json_ok(['id' => $id], 201);
  }

  public static function summary($shiftId) {
    need_role(['admin']);
    $shift = ShiftsRepo::get((int)$shiftId);
    if (!$shift) json_err('NOT_FOUND', 'Shift not found', [], 404);
    $from = $shift['opened_at'];
    $to = $shift['closed_at'] ?? date('Y-m-d H:i:s');
    $pdo = pdo();
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
    $moveStmt->execute([(int)$shiftId]);
    $moves = $moveStmt->fetch() ?: ['cash_in' => 0, 'cash_out' => 0];

    $expectedCash = (float)$shift['opening_float'] + (float)$sales['cash_sales']
                    + (float)$moves['cash_in'] - (float)$moves['cash_out'];
    $closingCash = $shift['closing_cash'] !== null ? (float)$shift['closing_cash'] : null;
    $diff = $closingCash !== null ? $closingCash - $expectedCash : null;

    json_ok([
      'shift' => self::sanitize($shift),
      'cash_sales' => (float)$sales['cash_sales'],
      'total_sales' => (float)$sales['total_sales'],
      'cash_in' => (float)$moves['cash_in'],
      'cash_out' => (float)$moves['cash_out'],
      'expected_cash' => $expectedCash,
      'closing_cash' => $closingCash,
      'difference' => $diff,
    ]);
  }
}
