<?php
// controllers/ToolsController.php
require_once __DIR__ . '/../lib/http.php';
require_once __DIR__ . '/../lib/auth.php';
require_once __DIR__ . '/../lib/db.php';
require_once __DIR__ . '/../repos/CategoriesRepo.php';
require_once __DIR__ . '/../repos/ModifiersRepo.php';

class ToolsController {
  public static function exportMenu() {
    need_role(['admin']);
    $categories = CategoriesRepo::listAll();
    $groups = ModifiersRepo::listGroups();
    $groupIds = array_column($groups, 'id');
    $options = [];
    foreach ($groupIds as $gid) {
      $options[$gid] = ModifiersRepo::listOptions($gid);
    }
    $data = [
      'categories' => array_map(function ($row) {
        return [
          'name' => $row['name'],
          'image_path' => $row['image_path'],
          'banner_path' => $row['banner_path'],
          'sort' => (int)$row['sort'],
        ];
      }, $categories),
      'modifier_groups' => array_map(function ($row) use ($options) {
        $gid = (int)$row['id'];
        return [
          'name' => $row['name'],
          'description' => $row['description'],
          'min_select' => (int)$row['min_select'],
          'max_select' => $row['max_select'] !== null ? (int)$row['max_select'] : null,
          'required' => (int)$row['required'] === 1,
          'sort' => (int)$row['sort'],
          'options' => array_map(function ($opt) {
            return [
              'name' => $opt['name'],
              'price_delta' => (float)$opt['price_delta'],
              'allow_qty' => (int)$opt['allow_qty'] === 1,
              'max_qty' => $opt['max_qty'] !== null ? (int)$opt['max_qty'] : null,
              'is_default' => (int)$opt['is_default'] === 1,
              'sort' => (int)$opt['sort'],
            ];
          }, $options[$gid] ?? []),
        ];
      }, $groups),
    ];
    json_ok($data);
  }

  public static function importMenu() {
    need_role(['admin']);
    $b = input_json();
    $categories = $b['categories'] ?? [];
    $groups = $b['modifier_groups'] ?? [];
    $pdo = pdo();
    $pdo->beginTransaction();
    try {
      foreach ($categories as $cat) {
        if (empty($cat['name'])) continue;
        $stmt = $pdo->prepare('SELECT id FROM categories WHERE name=?');
        $stmt->execute([$cat['name']]);
        $existing = $stmt->fetchColumn();
        if ($existing) {
          CategoriesRepo::update((int)$existing, [
            'name' => $cat['name'],
            'image_path' => $cat['image_path'] ?? null,
            'banner_path' => $cat['banner_path'] ?? null,
            'sort' => $cat['sort'] ?? 0,
          ]);
        } else {
          CategoriesRepo::insert([
            'name' => $cat['name'],
            'image_path' => $cat['image_path'] ?? null,
            'banner_path' => $cat['banner_path'] ?? null,
            'sort' => $cat['sort'] ?? 0,
          ]);
        }
      }
      foreach ($groups as $group) {
        if (empty($group['name'])) continue;
        $stmt = $pdo->prepare('SELECT id FROM modifier_groups WHERE name=?');
        $stmt->execute([$group['name']]);
        $groupId = $stmt->fetchColumn();
        $payload = [
          'name' => $group['name'],
          'min_select' => $group['min_select'] ?? 0,
          'max_select' => $group['max_select'] ?? null,
          'required' => !empty($group['required']) ? 1 : 0,
          'sort' => $group['sort'] ?? 0,
        ];
        if ($groupId) {
          ModifiersRepo::updateGroup((int)$groupId, $payload);
        } else {
          $groupId = ModifiersRepo::insertGroup($payload);
        }
        // replace options
        $pdo->prepare('DELETE FROM modifier_options WHERE group_id=?')->execute([(int)$groupId]);
        $opts = $group['options'] ?? [];
        foreach ($opts as $opt) {
          ModifiersRepo::insertOption((int)$groupId, [
            'name' => $opt['name'],
            'price_delta' => $opt['price_delta'] ?? 0,
            'allow_qty' => !empty($opt['allow_qty']),
            'max_qty' => $opt['max_qty'] ?? null,
            'is_default' => !empty($opt['is_default']),
            'sort' => $opt['sort'] ?? 0,
          ]);
        }
      }
      $pdo->commit();
    } catch (Throwable $e) {
      $pdo->rollBack();
      throw $e;
    }
    json_ok(['imported_categories' => count($categories), 'imported_groups' => count($groups)]);
  }

  public static function systemCheck() {
    need_role(['admin']);
    $pdo = pdo();
    $start = microtime(true);
    $pdo->query('SELECT 1');
    $latency = (microtime(true) - $start) * 1000;
    json_ok([
      'database' => 'ok',
      'db_latency_ms' => round($latency, 2),
      'server_time' => date('c'),
    ]);
  }
}
