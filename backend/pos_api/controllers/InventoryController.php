<?php
// controllers/InventoryController.php
require_once __DIR__ . '/../lib/http.php';
require_once __DIR__ . '/../lib/auth.php';
require_once __DIR__ . '/../repos/IngredientsRepo.php';
require_once __DIR__ . '/../repos/RecipesRepo.php';
require_once __DIR__ . '/../repos/StockRepo.php';

class InventoryController {
  private static function sanitizeIngredient(array $row): array {
    return [
      'id' => (int)$row['id'],
      'name' => $row['name'],
      'unit' => $row['unit'],
      'cost' => (float)$row['cost'],
      'enabled' => (int)$row['enabled'] === 1,
    ];
  }

  public static function ingredients() {
    need_role(['admin']);
    $enabledParam = $_GET['enabled'] ?? null;
    $enabled = null;
    if ($enabledParam === '1' || $enabledParam === '0') {
      $enabled = (int)$enabledParam;
    }
    $rows = IngredientsRepo::list(query('q'), $enabled);
    json_ok(array_map(fn($row) => self::sanitizeIngredient($row), $rows));
  }

  public static function createIngredient() {
    need_role(['admin']);
    $b = input_json();
    require_fields($b, ['name', 'unit']);
    $payload = [
      'name' => $b['name'],
      'unit' => $b['unit'],
      'cost' => isset($b['cost']) ? (float)$b['cost'] : 0,
      'enabled' => isset($b['enabled']) ? (int)$b['enabled'] : 1,
    ];
    $id = IngredientsRepo::insert($payload);
    $row = IngredientsRepo::get($id);
    json_ok(self::sanitizeIngredient($row), 201);
  }

  public static function updateIngredient($id) {
    need_role(['admin']);
    $b = input_json();
    require_fields($b, ['name', 'unit']);
    $payload = [
      'name' => $b['name'],
      'unit' => $b['unit'],
      'cost' => isset($b['cost']) ? (float)$b['cost'] : 0,
      'enabled' => isset($b['enabled']) ? (int)$b['enabled'] : 1,
    ];
    IngredientsRepo::update((int)$id, $payload);
    $row = IngredientsRepo::get((int)$id);
    if (!$row) json_err('NOT_FOUND', 'Ingredient not found', [], 404);
    json_ok(self::sanitizeIngredient($row));
  }

  public static function deleteIngredient($id) {
    need_role(['admin']);
    try {
      IngredientsRepo::delete((int)$id);
    } catch (PDOException $e) {
      if ($e->getCode() === '23000') {
        json_err('CONSTRAINT_ERROR', 'Không thể xoá nguyên liệu đang được sử dụng', [], 409);
      }
      throw $e;
    }
    json_ok(['id' => (int)$id]);
  }

  public static function getRecipe($itemId) {
    need_role(['admin']);
    $rows = RecipesRepo::getForItem((int)$itemId);
    $data = array_map(function ($row) {
      return [
        'ingredient_id' => (int)$row['ingredient_id'],
        'ingredient_name' => $row['name'],
        'unit' => $row['unit'],
        'qty' => (float)$row['qty'],
      ];
    }, $rows);
    json_ok($data);
  }

  public static function setRecipe($itemId) {
    need_role(['admin']);
    $b = input_json();
    $rows = $b['ingredients'] ?? [];
    $payload = [];
    foreach ($rows as $row) {
      if (!isset($row['ingredient_id'], $row['qty'])) continue;
      $qty = (float)$row['qty'];
      if ($qty <= 0) continue;
      $payload[] = [
        'ingredient_id' => (int)$row['ingredient_id'],
        'qty' => $qty,
      ];
    }
    RecipesRepo::setForItem((int)$itemId, $payload);
    json_ok(['item_id' => (int)$itemId, 'count' => count($payload)]);
  }

  public static function stockMoves() {
    need_role(['admin']);
    $filters = [
      'ingredient_id' => query('ingredient_id'),
      'from' => query('from'),
      'to' => query('to'),
    ];
    $rows = StockRepo::listMoves($filters);
    $data = array_map(function ($row) {
      return [
        'id' => (int)$row['id'],
        'ingredient_id' => (int)$row['ingredient_id'],
        'ingredient_name' => $row['ingredient_name'],
        'unit' => $row['unit'],
        'move_type' => $row['move_type'],
        'qty' => (float)$row['qty'],
        'ref_entity' => $row['ref_entity'],
        'ref_id' => $row['ref_id'] ? (int)$row['ref_id'] : null,
        'note' => $row['note'],
        'created_at' => $row['created_at'],
      ];
    }, $rows);
    json_ok($data);
  }

  public static function stockIn() {
    need_role(['admin']);
    self::recordMove('in');
  }

  public static function stockAdjust() {
    need_role(['admin']);
    self::recordMove('adjust');
  }

  private static function recordMove(string $type) {
    $b = input_json();
    require_fields($b, ['ingredient_id', 'qty']);
    $qty = (float)$b['qty'];
    if ($qty <= 0) json_err('VALIDATION_FAILED', 'Số lượng phải lớn hơn 0', ['field' => 'qty'], 422);
    $payload = [
      'ingredient_id' => (int)$b['ingredient_id'],
      'move_type' => $type,
      'qty' => $qty,
      'ref_entity' => $b['ref_entity'] ?? null,
      'ref_id' => isset($b['ref_id']) ? (int)$b['ref_id'] : null,
      'note' => $b['note'] ?? null,
    ];
    $id = StockRepo::addMove($payload);
    json_ok(['id' => $id], 201);
  }

  public static function stockSummary() {
    need_role(['admin']);
    $rows = StockRepo::currentStock();
    $data = array_map(function ($row) {
      return [
        'ingredient_id' => (int)$row['ingredient_id'],
        'ingredient_name' => $row['name'],
        'unit' => $row['unit'],
        'qty' => (float)$row['qty'],
      ];
    }, $rows);
    json_ok($data);
  }

  public static function consumption() {
    need_role(['admin']);
    $filters = [
      'from' => query('from'),
      'to' => query('to'),
    ];
    $rows = StockRepo::consumption($filters);
    $data = array_map(function ($row) {
      return [
        'ingredient_id' => (int)$row['ingredient_id'],
        'ingredient_name' => $row['name'],
        'unit' => $row['unit'],
        'qty' => (float)$row['qty'],
      ];
    }, $rows);
    json_ok($data);
  }
}
