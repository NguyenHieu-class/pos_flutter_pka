<?php
// controllers/DiscountsController.php
require_once __DIR__ . '/../lib/http.php';
require_once __DIR__ . '/../lib/auth.php';
require_once __DIR__ . '/../repos/DiscountsRepo.php';

class DiscountsController {
  private static function sanitize(array $row): array {
    return [
      'id' => (int)$row['id'],
      'code' => $row['code'],
      'name' => $row['name'],
      'type' => $row['type'],
      'value' => (float)$row['value'],
      'min_subtotal' => (float)$row['min_subtotal'],
      'active' => (int)$row['active'] === 1,
      'starts_at' => $row['starts_at'],
      'ends_at' => $row['ends_at'],
    ];
  }

  public static function list() {
    need_role(['admin']);
    $filters = [
      'q' => query('q'),
    ];
    if (($active = query('active')) !== null) {
      if ($active === '1' || $active === '0') {
        $filters['active'] = (int)$active;
      }
    }
    $rows = DiscountsRepo::list($filters);
    json_ok(array_map(fn($row) => self::sanitize($row), $rows));
  }

  public static function create() {
    need_role(['admin']);
    $b = input_json();
    require_fields($b, ['name', 'type', 'value']);
    if (!in_array($b['type'], ['percent', 'amount'], true)) {
      json_err('VALIDATION_FAILED', 'Kiểu giảm giá không hợp lệ', ['field' => 'type'], 422);
    }
    $payload = [
      'code' => isset($b['code']) ? strtoupper(trim($b['code'])) : null,
      'name' => $b['name'],
      'type' => $b['type'],
      'value' => (float)$b['value'],
      'min_subtotal' => isset($b['min_subtotal']) ? (float)$b['min_subtotal'] : 0,
      'active' => isset($b['active']) ? (int)$b['active'] : 1,
      'starts_at' => $b['starts_at'] ?? null,
      'ends_at' => $b['ends_at'] ?? null,
    ];
    $id = DiscountsRepo::insert($payload);
    $row = DiscountsRepo::get($id);
    json_ok(self::sanitize($row), 201);
  }

  public static function update($id) {
    need_role(['admin']);
    $b = input_json();
    require_fields($b, ['name', 'type', 'value']);
    if (!in_array($b['type'], ['percent', 'amount'], true)) {
      json_err('VALIDATION_FAILED', 'Kiểu giảm giá không hợp lệ', ['field' => 'type'], 422);
    }
    $payload = [
      'code' => isset($b['code']) ? strtoupper(trim($b['code'])) : null,
      'name' => $b['name'],
      'type' => $b['type'],
      'value' => (float)$b['value'],
      'min_subtotal' => isset($b['min_subtotal']) ? (float)$b['min_subtotal'] : 0,
      'active' => isset($b['active']) ? (int)$b['active'] : 1,
      'starts_at' => $b['starts_at'] ?? null,
      'ends_at' => $b['ends_at'] ?? null,
    ];
    DiscountsRepo::update((int)$id, $payload);
    $row = DiscountsRepo::get((int)$id);
    if (!$row) json_err('NOT_FOUND', 'Discount not found', [], 404);
    json_ok(self::sanitize($row));
  }

  public static function delete($id) {
    need_role(['admin']);
    DiscountsRepo::delete((int)$id);
    json_ok(['id' => (int)$id]);
  }

  public static function history() {
    need_role(['admin']);
    $filters = [
      'discount_id' => query('discount_id'),
      'from' => query('from'),
      'to' => query('to'),
    ];
    $rows = DiscountsRepo::usageHistory($filters);
    $data = array_map(function ($row) {
      return [
        'id' => (int)$row['id'],
        'order_id' => (int)$row['order_id'],
        'order_code' => $row['order_code'],
        'discount_id' => $row['discount_id'] ? (int)$row['discount_id'] : null,
        'code' => $row['code'],
        'name' => $row['name'],
        'type' => $row['type'],
        'value' => (float)$row['value'],
        'amount' => (float)$row['amount'],
        'order_total' => (float)$row['total'],
        'closed_at' => $row['closed_at'],
      ];
    }, $rows);
    json_ok($data);
  }
}
