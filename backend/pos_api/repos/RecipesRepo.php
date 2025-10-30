<?php
// repos/RecipesRepo.php
require_once __DIR__ . '/../lib/db.php';

class RecipesRepo {
  public static function getForItem(int $itemId): array {
    $sql = "SELECT ir.ingredient_id, ir.qty, i.name, i.unit
            FROM item_recipes ir
            JOIN ingredients i ON i.id = ir.ingredient_id
            WHERE ir.item_id=?
            ORDER BY i.name";
    $s = pdo()->prepare($sql);
    $s->execute([$itemId]);
    return $s->fetchAll();
  }

  public static function setForItem(int $itemId, array $rows): void {
    $pdo = pdo();
    $pdo->beginTransaction();
    try {
      $pdo->prepare("DELETE FROM item_recipes WHERE item_id=?")->execute([$itemId]);
      if (!empty($rows)) {
        $stmt = $pdo->prepare("INSERT INTO item_recipes(item_id, ingredient_id, qty) VALUES(?,?,?)");
        foreach ($rows as $row) {
          $stmt->execute([$itemId, $row['ingredient_id'], $row['qty']]);
        }
      }
      $pdo->commit();
    } catch (Throwable $e) {
      $pdo->rollBack();
      throw $e;
    }
  }
}
