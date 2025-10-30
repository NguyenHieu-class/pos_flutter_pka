<?php
// controllers/CategoriesController.php
require_once __DIR__ . '/../lib/http.php';
require_once __DIR__ . '/../lib/auth.php';
require_once __DIR__ . '/../lib/media.php';
require_once __DIR__ . '/../repos/CategoriesRepo.php';
require_once __DIR__ . '/../repos/MediaRepo.php';

class CategoriesController {
  public static function list() {
    $rows = CategoriesRepo::listAll();
    $ids = array_column($rows, 'id');
    $primaryMap = primary_media_map('category', $ids);
    foreach ($rows as &$r) {
      $r['image_url']  = resolve_category_image($r, $primaryMap);
      $r['banner_url'] = resolve_category_banner($r);
    }
    json_ok($rows);
  }

  public static function create() {
    need_role(['admin']);
    $b = input_json(); require_fields($b,['name']);
    $id = CategoriesRepo::insert($b);
    json_ok(['id'=>$id], 201);
  }

  public static function update($id) {
    need_role(['admin']);
    $b = input_json(); require_fields($b,['name']);
    CategoriesRepo::update((int)$id, $b);
    json_ok(['id'=>(int)$id]);
  }

  public static function delete($id) {
    need_role(['admin']);
    CategoriesRepo::delete((int)$id);
    json_ok(['id'=>(int)$id]);
  }

  // gán primary/banner từ media_id
  public static function setImage($id) {
    need_role(['admin']);
    $b = $_POST + (input_json() ?: []);
    require_fields($b, ['media_id']);
    $role = $b['role'] ?? 'primary'; // 'primary' | 'banner' | 'thumbnail'
    MediaRepo::setPrimary('category', (int)$id, (int)$b['media_id'], $role);
    json_ok(['category_id'=>(int)$id, 'media_id'=>(int)$b['media_id'], 'role'=>$role]);
  }
}
