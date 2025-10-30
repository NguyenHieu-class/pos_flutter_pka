<?php
// controllers/PaymentMethodsController.php
require_once __DIR__ . '/../lib/http.php';
require_once __DIR__ . '/../lib/auth.php';
require_once __DIR__ . '/../repos/PaymentMethodsRepo.php';

class PaymentMethodsController {
  private static function sanitize(array $row): array {
    return [
      'id' => (int)$row['id'],
      'code' => $row['code'],
      'name' => $row['name'],
      'enabled' => (int)$row['enabled'] === 1,
    ];
  }

  public static function list() {
    need_role(['admin']);
    $enabled = null;
    $enabledParam = query('enabled');
    if ($enabledParam === '1' || $enabledParam === '0') {
      $enabled = (int)$enabledParam;
    }
    $rows = PaymentMethodsRepo::list(query('q'), $enabled);
    json_ok(array_map(fn($row) => self::sanitize($row), $rows));
  }

  public static function create() {
    need_role(['admin']);
    $b = input_json();
    require_fields($b, ['code', 'name']);
    $payload = [
      'code' => strtoupper(trim($b['code'])),
      'name' => $b['name'],
      'enabled' => isset($b['enabled']) ? (int)$b['enabled'] : 1,
    ];
    $id = PaymentMethodsRepo::insert($payload);
    $row = PaymentMethodsRepo::get($id);
    json_ok(self::sanitize($row), 201);
  }

  public static function update($id) {
    need_role(['admin']);
    $b = input_json();
    require_fields($b, ['code', 'name']);
    $payload = [
      'code' => strtoupper(trim($b['code'])),
      'name' => $b['name'],
      'enabled' => isset($b['enabled']) ? (int)$b['enabled'] : 1,
    ];
    PaymentMethodsRepo::update((int)$id, $payload);
    $row = PaymentMethodsRepo::get((int)$id);
    if (!$row) json_err('NOT_FOUND', 'Payment method not found', [], 404);
    json_ok(self::sanitize($row));
  }

  public static function delete($id) {
    need_role(['admin']);
    try {
      PaymentMethodsRepo::delete((int)$id);
    } catch (PDOException $e) {
      if ($e->getCode() === '23000') {
        json_err('CONSTRAINT_ERROR', 'Không thể xoá phương thức đã phát sinh giao dịch', [], 409);
      }
      throw $e;
    }
    json_ok(['id' => (int)$id]);
  }

  public static function orderPayments($orderId) {
    need_role(['admin']);
    $rows = PaymentMethodsRepo::paymentsForOrder((int)$orderId);
    $data = array_map(function ($row) {
      return [
        'id' => (int)$row['id'],
        'order_id' => (int)$row['order_id'],
        'method_id' => (int)$row['method_id'],
        'method_code' => $row['method_code'],
        'method_name' => $row['method_name'],
        'amount' => (float)$row['amount'],
        'paid_at' => $row['paid_at'],
        'ref_no' => $row['ref_no'],
      ];
    }, $rows);
    json_ok($data);
  }
}
