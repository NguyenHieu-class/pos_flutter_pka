<?php
// controllers/ReasonCodesController.php
require_once __DIR__ . '/../lib/http.php';
require_once __DIR__ . '/../lib/auth.php';
require_once __DIR__ . '/../repos/ReasonCodesRepo.php';

class ReasonCodesController {
  private static function sanitize(array $row): array {
    return [
      'id' => (int)$row['id'],
      'code' => $row['code'],
      'description' => $row['description'],
    ];
  }

  public static function list() {
    need_role(['admin']);
    $rows = ReasonCodesRepo::list(query('q'));
    json_ok(array_map(fn($row) => self::sanitize($row), $rows));
  }

  public static function create() {
    need_role(['admin']);
    $b = input_json();
    require_fields($b, ['code', 'description']);
    $id = ReasonCodesRepo::insert([
      'code' => strtoupper(trim($b['code'])),
      'description' => $b['description'],
    ]);
    $row = ReasonCodesRepo::get($id);
    json_ok(self::sanitize($row), 201);
  }

  public static function update($id) {
    need_role(['admin']);
    $b = input_json();
    require_fields($b, ['code', 'description']);
    ReasonCodesRepo::update((int)$id, [
      'code' => strtoupper(trim($b['code'])),
      'description' => $b['description'],
    ]);
    $row = ReasonCodesRepo::get((int)$id);
    if (!$row) json_err('NOT_FOUND', 'Reason not found', [], 404);
    json_ok(self::sanitize($row));
  }

  public static function delete($id) {
    need_role(['admin']);
    try {
      ReasonCodesRepo::delete((int)$id);
    } catch (PDOException $e) {
      if ($e->getCode() === '23000') {
        json_err('CONSTRAINT_ERROR', 'Không thể xoá lý do đang được sử dụng', [], 409);
      }
      throw $e;
    }
    json_ok(['id' => (int)$id]);
  }
}
