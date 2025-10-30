<?php
// controllers/KitchenController.php
require_once __DIR__ . '/../lib/http.php';
require_once __DIR__ . '/../lib/auth.php';
require_once __DIR__ . '/../repos/KitchenRepo.php';

class KitchenController {
  public static function queue() {
    need_role(['admin','kitchen','cashier']);
    $filters = self::filtersFromQuery();
    $rows = KitchenRepo::queue($filters);
    json_ok($rows);
  }

  public static function history() {
    need_role(['admin','kitchen']);
    $filters = self::filtersFromQuery();
    if (!isset($filters['statuses']) || count($filters['statuses']) === 0) {
      $filters['statuses'] = ['ready', 'served', 'cancelled'];
    }
    $rows = KitchenRepo::history($filters);
    json_ok($rows);
  }

  public static function setItemStatus($orderItemId) {
    need_role(['admin','kitchen']);
    $b = input_json(); require_fields($b,['kitchen_status']);
    $valid=['queued','preparing','ready','served','cancelled'];
    $status = $b['kitchen_status'];
    if (!in_array($status,$valid,true)) json_err('VALIDATION_FAILED','Invalid kitchen_status',[],422);
    $reason = $b['cancel_reason'] ?? null;
    if ($status === 'cancelled') {
      if (!$reason || trim($reason) === '') {
        json_err('VALIDATION_FAILED','Lý do huỷ bắt buộc', ['field' => 'cancel_reason'], 422);
      }
    }
    KitchenRepo::setItemStatus((int)$orderItemId, $status, $reason);
    json_ok(['order_item_id'=>(int)$orderItemId,'kitchen_status'=>$status]);
  }

  private static function filtersFromQuery(): array {
    $filters = [];
    $stationId = query('station_id');
    if ($stationId !== null && $stationId !== '') {
      $filters['station_id'] = (int)$stationId;
    }
    $area = query('area_code');
    if ($area) {
      $filters['area_code'] = $area;
    }
    $table = query('table_code');
    if ($table) {
      $filters['table_code'] = $table;
    }
    $categoryId = query('category_id');
    if ($categoryId !== null && $categoryId !== '') {
      $filters['category_id'] = (int)$categoryId;
    }
    $statuses = query('statuses');
    if ($statuses) {
      $list = array_filter(array_map('trim', explode(',', $statuses)));
      if (count($list) > 0) {
        $filters['statuses'] = array_values(array_unique($list));
      }
    }
    return $filters;
  }
}
