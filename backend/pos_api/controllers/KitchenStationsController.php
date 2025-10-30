<?php
// controllers/KitchenStationsController.php
require_once __DIR__ . '/../lib/http.php';
require_once __DIR__ . '/../lib/auth.php';
require_once __DIR__ . '/../repos/StationsRepo.php';
require_once __DIR__ . '/../repos/MediaRepo.php';
require_once __DIR__ . '/../lib/media.php';

class KitchenStationsController {
  private static function sanitize(array $row): array {
    $row['id'] = (int)$row['id'];
    $row['sort'] = (int)($row['sort'] ?? 0);
    $row['icon_url'] = resolve_station_icon($row, primary_media_map('station', [$row['id']]));
    return $row;
  }

  public static function list() {
    need_role(['admin']);
    $rows = StationsRepo::list(query('q'));
    $ids = array_column($rows, 'id');
    $media = primary_media_map('station', $ids);
    $data = array_map(function ($row) use ($media) {
      $row['id'] = (int)$row['id'];
      $row['sort'] = (int)($row['sort'] ?? 0);
      $row['icon_url'] = resolve_station_icon($row, $media);
      return $row;
    }, $rows);
    json_ok($data);
  }

  public static function create() {
    need_role(['admin']);
    $b = input_json();
    require_fields($b, ['name']);
    $payload = [
      'name' => $b['name'],
      'icon_path' => $b['icon_path'] ?? null,
      'sort' => isset($b['sort']) ? (int)$b['sort'] : 0,
    ];
    $id = StationsRepo::insert($payload);
    $row = StationsRepo::get($id);
    json_ok(self::sanitize($row), 201);
  }

  public static function update($id) {
    need_role(['admin']);
    $b = input_json();
    require_fields($b, ['name']);
    $payload = [
      'name' => $b['name'],
      'icon_path' => $b['icon_path'] ?? null,
      'sort' => isset($b['sort']) ? (int)$b['sort'] : 0,
    ];
    StationsRepo::update((int)$id, $payload);
    $row = StationsRepo::get((int)$id);
    if (!$row) json_err('NOT_FOUND', 'Station not found', [], 404);
    json_ok(self::sanitize($row));
  }

  public static function delete($id) {
    need_role(['admin']);
    try {
      StationsRepo::delete((int)$id);
    } catch (PDOException $e) {
      if ($e->getCode() === '23000') {
        json_err('CONSTRAINT_ERROR', 'Không thể xoá trạm bếp đang được sử dụng', [], 409);
      }
      throw $e;
    }
    json_ok(['id' => (int)$id]);
  }

  public static function setIcon($id) {
    need_role(['admin']);
    $b = $_POST + (input_json() ?: []);
    require_fields($b, ['media_id']);
    MediaRepo::setPrimary('station', (int)$id, (int)$b['media_id'], 'icon');
    if (isset($b['icon_path'])) {
      StationsRepo::updateIconPath((int)$id, $b['icon_path'] ?: null);
    }
    json_ok(['station_id' => (int)$id, 'media_id' => (int)$b['media_id']]);
  }
}
