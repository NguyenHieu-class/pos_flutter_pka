<?php
// repos/ModifiersRepo.php
require_once __DIR__ . '/../lib/db.php';
require_once __DIR__ . '/../lib/http.php';

class ModifiersRepo {
  public static function listGroups(): array {
    $sql = "SELECT mg.*, COUNT(mo.id) AS option_count
            FROM modifier_groups mg
            LEFT JOIN modifier_options mo ON mo.group_id = mg.id
            GROUP BY mg.id
            ORDER BY mg.sort, mg.id";
    $stmt = pdo()->query($sql);
    return $stmt->fetchAll();
  }

  public static function getGroup(int $id): ?array {
    $stmt = pdo()->prepare("SELECT * FROM modifier_groups WHERE id=?");
    $stmt->execute([$id]);
    $row = $stmt->fetch();
    return $row ?: null;
  }

  public static function insertGroup(array $payload): int {
    $sql = "INSERT INTO modifier_groups(name, description, min_select, max_select, required, sort)
            VALUES(?,?,?,?,?,?)";
    pdo()->prepare($sql)->execute([
      $payload['name'],
      $payload['description'] ?? null,
      $payload['min_select'] ?? 0,
      $payload['max_select'] ?? null,
      !empty($payload['required']) ? 1 : 0,
      $payload['sort'] ?? 0,
    ]);
    return (int)pdo()->lastInsertId();
  }

  public static function updateGroup(int $id, array $payload): void {
    $sql = "UPDATE modifier_groups
            SET name=?, description=?, min_select=?, max_select=?, required=?, sort=?
            WHERE id=?";
    pdo()->prepare($sql)->execute([
      $payload['name'],
      $payload['description'] ?? null,
      $payload['min_select'] ?? 0,
      $payload['max_select'] ?? null,
      !empty($payload['required']) ? 1 : 0,
      $payload['sort'] ?? 0,
      $id,
    ]);
  }

  public static function deleteGroup(int $id): void {
    $pdo = pdo();
    $pdo->prepare("DELETE FROM item_modifier_groups WHERE group_id=?")->execute([$id]);
    $pdo->prepare("DELETE FROM modifier_options WHERE group_id=?")->execute([$id]);
    $pdo->prepare("DELETE FROM modifier_groups WHERE id=?")->execute([$id]);
  }

  public static function listOptions(int $groupId): array {
    $sql = "SELECT * FROM modifier_options WHERE group_id=? ORDER BY sort, id";
    $stmt = pdo()->prepare($sql);
    $stmt->execute([$groupId]);
    return $stmt->fetchAll();
  }

  public static function insertOption(int $groupId, array $payload): int {
    $sql = "INSERT INTO modifier_options(group_id, name, price_delta, allow_qty, max_qty, is_default, sort)
            VALUES(?,?,?,?,?,?,?)";
    pdo()->prepare($sql)->execute([
      $groupId,
      $payload['name'],
      $payload['price_delta'] ?? 0,
      !empty($payload['allow_qty']) ? 1 : 0,
      $payload['max_qty'] ?? null,
      !empty($payload['is_default']) ? 1 : 0,
      $payload['sort'] ?? 0,
    ]);
    return (int)pdo()->lastInsertId();
  }

  public static function updateOption(int $id, array $payload): void {
    $sql = "UPDATE modifier_options
            SET name=?, price_delta=?, allow_qty=?, max_qty=?, is_default=?, sort=?
            WHERE id=?";
    pdo()->prepare($sql)->execute([
      $payload['name'],
      $payload['price_delta'] ?? 0,
      !empty($payload['allow_qty']) ? 1 : 0,
      $payload['max_qty'] ?? null,
      !empty($payload['is_default']) ? 1 : 0,
      $payload['sort'] ?? 0,
      $id,
    ]);
  }

  public static function deleteOption(int $id): void {
    pdo()->prepare("DELETE FROM modifier_options WHERE id=?")->execute([$id]);
  }

  public static function listItemGroups(int $itemId): array {
    $sql = "SELECT img.group_id, mg.name
            FROM item_modifier_groups img
            JOIN modifier_groups mg ON mg.id = img.group_id
            WHERE img.item_id=?
            ORDER BY mg.sort, mg.id";
    $stmt = pdo()->prepare($sql);
    $stmt->execute([$itemId]);
    return $stmt->fetchAll();
  }

  public static function replaceItemGroups(int $itemId, array $groupIds): void {
    $pdo = pdo();
    $pdo->beginTransaction();
    try {
      $pdo->prepare("DELETE FROM item_modifier_groups WHERE item_id=?")->execute([$itemId]);
      if ($groupIds) {
        $placeholders = implode(',', array_fill(0, count($groupIds), '?'));
        $check = $pdo->prepare("SELECT id FROM modifier_groups WHERE id IN ($placeholders)");
        $check->execute($groupIds);
        $found = array_column($check->fetchAll(), 'id');
        sort($found);
        $expected = $groupIds;
        sort($expected);
        if ($found !== $expected) {
          $pdo->rollBack();
          json_err('VALIDATION_FAILED', 'Invalid modifier group id provided', [], 422);
        }
        $ins = $pdo->prepare("INSERT INTO item_modifier_groups(item_id, group_id) VALUES(?,?)");
        foreach ($groupIds as $groupId) {
          $ins->execute([$itemId, $groupId]);
        }
      }
      $pdo->commit();
    } catch (Throwable $e) {
      $pdo->rollBack();
      throw $e;
    }
  }
}
