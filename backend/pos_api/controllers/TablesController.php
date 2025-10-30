<?php
// controllers/TablesController.php
require_once __DIR__ . '/../lib/http.php';
require_once __DIR__ . '/../lib/media.php';
require_once __DIR__ . '/../repos/TablesRepo.php';
require_once __DIR__ . '/../repos/MediaRepo.php';
require_once __DIR__ . '/../lib/auth.php';

class TablesController {
  public static function areas() {
    $rows = TablesRepo::areas();
    $ids = array_column($rows, 'id');
    $primaryMap = primary_media_map('area', $ids);
    foreach ($rows as &$r) $r['image_url'] = resolve_area_image($r, $primaryMap);
    json_ok($rows);
  }

  public static function createArea() {
    need_role(['admin']);
    $b = input_json(); require_fields($b, ['name']);
    $id = TablesRepo::insertArea($b);
    json_ok(['id' => $id], 201);
  }

  public static function updateArea($id) {
    need_role(['admin']);
    $b = input_json(); require_fields($b, ['name']);
    TablesRepo::updateArea((int)$id, $b);
    json_ok(['id' => (int)$id]);
  }

  public static function deleteArea($id) {
    need_role(['admin']);
    TablesRepo::deleteArea((int)$id);
    json_ok(['id' => (int)$id]);
  }

  public static function setAreaImage($id) {
    need_role(['admin']);
    $b = $_POST + (input_json() ?: []);
    require_fields($b, ['media_id']);
    MediaRepo::setPrimary('area', (int)$id, (int)$b['media_id'], 'primary');
    if (isset($b['image_path'])) {
      TablesRepo::updateAreaImage((int)$id, $b['image_path'] ?: null);
    }
    json_ok(['area_id' => (int)$id, 'media_id' => (int)$b['media_id']]);
  }

  public static function tables() {
    json_ok(TablesRepo::tables(query('area_id'), query('status')));
  }

  public static function createTable() {
    need_role(['admin']);
    $b = input_json(); require_fields($b, ['area_id','name']);
    if (isset($b['status']) && !in_array($b['status'], ['free','occupied','cleaning'], true)) {
      json_err('VALIDATION_FAILED','Invalid status',[],422);
    }
    $id = TablesRepo::insertTable($b);
    json_ok(['id' => $id], 201);
  }

  public static function updateTable($id) {
    need_role(['admin']);
    $b = input_json(); require_fields($b, ['area_id','name']);
    if (isset($b['status']) && !in_array($b['status'], ['free','occupied','cleaning'], true)) {
      json_err('VALIDATION_FAILED','Invalid status',[],422);
    }
    TablesRepo::updateTable((int)$id, $b);
    json_ok(['id' => (int)$id]);
  }

  public static function deleteTable($id) {
    need_role(['admin']);
    TablesRepo::deleteTable((int)$id);
    json_ok(['id' => (int)$id]);
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
