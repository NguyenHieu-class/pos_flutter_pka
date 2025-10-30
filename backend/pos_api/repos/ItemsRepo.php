<?php
// repos/ItemsRepo.php
require_once __DIR__ . '/../lib/db.php';

class ItemsRepo {
  public static function list($categoryId=null, $q=null, $enabled=1) {
    $sql = "SELECT i.*, c.name AS category_name, ks.name AS station_name
            FROM items i
            JOIN categories c ON c.id=i.category_id
            LEFT JOIN kitchen_stations ks ON ks.id=i.station_id
            WHERE 1=1";
    $args = [];
    if ($enabled !== null) { $sql.=" AND i.enabled=?"; $args[]=(int)$enabled; }
    if ($categoryId) { $sql.=" AND i.category_id=?"; $args[]=(int)$categoryId; }
    if ($q) { $sql.=" AND (i.name LIKE ? OR i.sku LIKE ?)"; $args[]="%$q%"; $args[]="%$q%"; }
    $sql .= " ORDER BY c.sort, i.name";
    $s = pdo()->prepare($sql); $s->execute($args); return $s->fetchAll();
  }
  public static function get(int $id) {
    $s = pdo()->prepare("SELECT * FROM items WHERE id=?"); $s->execute([$id]); return $s->fetch();
  }
  public static function insert(array $b): int {
    $sql="INSERT INTO items(category_id,station_id,sku,name,description,price,tax_rate,enabled,image_path)
          VALUES(?,?,?,?,?,?,?,?,?)";
    pdo()->prepare($sql)->execute([
      $b['category_id'], $b['station_id'] ?? null, $b['sku'] ?? null,
      $b['name'], $b['description'] ?? null, $b['price'], $b['tax_rate'] ?? 0,
      $b['enabled'] ?? 1, $b['image_path'] ?? null
    ]);
    return (int)pdo()->lastInsertId();
  }
  public static function update(int $id, array $b) {
    $sql="UPDATE items SET category_id=?, station_id=?, sku=?, name=?, description=?, price=?, tax_rate=?, enabled=?, image_path=? WHERE id=?";
    pdo()->prepare($sql)->execute([
      $b['category_id'], $b['station_id'] ?? null, $b['sku'] ?? null,
      $b['name'], $b['description'] ?? null, $b['price'], $b['tax_rate'] ?? 0,
      $b['enabled'] ?? 1, $b['image_path'] ?? null, $id
    ]);
  }
  public static function delete(int $id) {
    pdo()->prepare("DELETE FROM items WHERE id=?")->execute([$id]);
  }
  public static function modifiersForItem(int $itemId) {
    $sql="SELECT mg.id group_id, mg.name group_name, mg.min_select, mg.max_select, mg.required, mg.sort group_sort,
                 mo.id option_id, mo.name option_name, mo.price_delta, mo.allow_qty, mo.max_qty, mo.is_default, mo.sort option_sort
          FROM item_modifier_groups img
          JOIN modifier_groups mg ON mg.id=img.group_id
          JOIN modifier_options mo ON mo.group_id=mg.id
          WHERE img.item_id=?
          ORDER BY mg.sort, mg.id, mo.sort, mo.id";
    $s = pdo()->prepare($sql); $s->execute([$itemId]); return $s->fetchAll();
  }
}
