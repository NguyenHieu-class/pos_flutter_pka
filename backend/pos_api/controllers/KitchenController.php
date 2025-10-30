<?php
// controllers/KitchenController.php
require_once __DIR__ . '/../lib/http.php';
require_once __DIR__ . '/../lib/auth.php';
require_once __DIR__ . '/../repos/KitchenRepo.php';

class KitchenController {
  public static function queue() {
    need_role(['admin','kitchen','cashier']);
    $rows = KitchenRepo::queue(query('station_id'));
    json_ok($rows);
  }
  public static function setItemStatus($orderItemId) {
    need_role(['admin','kitchen']);
    $b = input_json(); require_fields($b,['kitchen_status']);
    $valid=['queued','preparing','ready','served','cancelled'];
    if (!in_array($b['kitchen_status'],$valid,true)) json_err('VALIDATION_FAILED','Invalid kitchen_status',[],422);
    KitchenRepo::setItemStatus((int)$orderItemId, $b['kitchen_status']);
    json_ok(['order_item_id'=>(int)$orderItemId,'kitchen_status'=>$b['kitchen_status']]);
  }
}
