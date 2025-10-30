<?php
// repos/CategoriesRepo.php
require_once __DIR__ . '/../lib/db.php';

class CategoriesRepo {
  public static function listAll() {
    return pdo()->query("SELECT * FROM categories ORDER BY sort, id")->fetchAll();
  }
  public static function get(int $id) {
    $s = pdo()->prepare("SELECT * FROM categories WHERE id=?"); $s->execute([$id]); return $s->fetch();
  }
  public static function insert(array $b): int {
    $s = pdo()->prepare("INSERT INTO categories(name,image_path,banner_path,sort) VALUES(?,?,?,?)");
    $s->execute([$b['name'], $b['image_path'] ?? null, $b['banner_path'] ?? null, $b['sort'] ?? 0]);
    return (int)pdo()->lastInsertId();
  }
  public static function update(int $id, array $b) {
    $s = pdo()->prepare("UPDATE categories SET name=?, image_path=?, banner_path=?, sort=? WHERE id=?");
    $s->execute([$b['name'], $b['image_path'] ?? null, $b['banner_path'] ?? null, $b['sort'] ?? 0, $id]);
  }
  public static function delete(int $id) {
    pdo()->prepare("DELETE FROM categories WHERE id=?")->execute([$id]);
  }
}
