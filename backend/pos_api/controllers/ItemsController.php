<?php
// controllers/ItemsController.php
require_once __DIR__ . '/../lib/http.php';
require_once __DIR__ . '/../lib/auth.php';
require_once __DIR__ . '/../lib/media.php';
require_once __DIR__ . '/../repos/ItemsRepo.php';
require_once __DIR__ . '/../repos/MediaRepo.php';

class ItemsController {
  public static function list() {
    $enabled = isset($_GET['enabled']) ? (int)$_GET['enabled'] : 1;
    $rows = ItemsRepo::list(query('category_id'), query('q'), $enabled);
    $ids = array_column($rows, 'id');
    $primaryMap = primary_media_map('item', $ids);
    foreach ($rows as &$r) $r['image_url'] = resolve_item_image($r, $primaryMap);
    json_ok($rows);
  }

  public static function get($id) {
    $row = ItemsRepo::get((int)$id);
    if (!$row) json_err('NOT_FOUND','Item not found',[],404);
    $row['image_url'] = resolve_item_image($row, primary_media_map('item', [$row['id']]));
    json_ok($row);
  }

  public static function create() {
    need_role(['admin']);
    $b = input_json(); require_fields($b, ['name','price','category_id']);
    $id = ItemsRepo::insert($b);
    json_ok(['id'=>$id], 201);
  }

  public static function update($id) {
    need_role(['admin']);
    $b = input_json(); require_fields($b, ['name','price','category_id']);
    ItemsRepo::update((int)$id, $b);
    json_ok(['id'=>(int)$id]);
  }

  public static function delete($id) {
    need_role(['admin']);
    ItemsRepo::delete((int)$id);
    json_ok(['id'=>(int)$id]);
  }

  public static function modifiers($id) {
    $rows = ItemsRepo::modifiersForItem((int)$id);
    $groups = [];
    foreach ($rows as $r) {
      $gid = $r['group_id'];
      if (!isset($groups[$gid])) {
        $groups[$gid] = [
          'group_id'=>$gid, 'name'=>$r['group_name'],
          'min_select'=>(int)$r['min_select'], 'max_select'=>(int)$r['max_select'],
          'required'=> (int)$r['required']===1,
          'options'=>[]
        ];
      }
      $groups[$gid]['options'][] = [
        'option_id'=>$r['option_id'], 'name'=>$r['option_name'],
        'price_delta'=>(float)$r['price_delta'],
        'allow_qty'=>(int)$r['allow_qty']===1, 'max_qty'=>(int)$r['max_qty'], 'is_default'=>(int)$r['is_default']===1
      ];
    }
    json_ok(array_values($groups));
  }

  public static function setImage($id) {
    need_role(['admin']);
    $b = $_POST + (input_json() ?: []);
    require_fields($b, ['media_id']);
    MediaRepo::setPrimary('item', (int)$id, (int)$b['media_id'], 'primary');
    json_ok(['item_id'=>(int)$id, 'media_id'=>(int)$b['media_id']]);
  }
}
