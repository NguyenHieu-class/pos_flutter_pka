<?php
// controllers/TablesController.php
require_once __DIR__ . '/../lib/http.php';
require_once __DIR__ . '/../lib/media.php';
require_once __DIR__ . '/../repos/TablesRepo.php';
require_once __DIR__ . '/../lib/auth.php';

class TablesController {
  public static function areas() {
    $rows = TablesRepo::areas();
    $ids = array_column($rows, 'id');
    $primaryMap = primary_media_map('area', $ids);
    foreach ($rows as &$r) $r['image_url'] = resolve_area_image($r, $primaryMap);
    json_ok($rows);
  }

  public static function tables() {
    json_ok(TablesRepo::tables(query('area_id'), query('status')));
  }

  public static function setStatus($id) {
    need_role(['admin','cashier']);
    $b = input_json(); require_fields($b, ['status']);
    $st = $b['status'];
    if (!in_array($st, ['free','occupied','cleaning'], true)) json_err('VALIDATION_FAILED','Invalid status',[],422);
    TablesRepo::setStatus((int)$id, $st);
    json_ok(['id'=>(int)$id, 'status'=>$st]);
  }
}
