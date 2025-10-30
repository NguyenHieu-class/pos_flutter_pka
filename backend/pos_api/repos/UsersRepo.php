<?php
// repos/UsersRepo.php
require_once __DIR__ . '/../lib/db.php';

class UsersRepo {
  public static function findByUsername(string $username) {
    $s = pdo()->prepare("SELECT * FROM users WHERE username=?");
    $s->execute([$username]); return $s->fetch();
  }

  public static function get(int $id) {
    $s = pdo()->prepare("SELECT * FROM users WHERE id=?");
    $s->execute([$id]);
    return $s->fetch();
  }

  public static function list(array $roles = []) {
    $sql = "SELECT id, name, username, role, phone, email, is_active, created_at, updated_at"
         . " FROM users";
    $args = [];
    if (!empty($roles)) {
      $placeholders = implode(',', array_fill(0, count($roles), '?'));
      $sql .= " WHERE role IN ($placeholders)";
      $args = array_values($roles);
    }
    $sql .= " ORDER BY role, name";
    $s = pdo()->prepare($sql);
    $s->execute($args);
    return $s->fetchAll();
  }

  public static function insert(array $b): int {
    $sql = "INSERT INTO users(name, username, password_plain, role, phone, email, is_active)"
         . " VALUES(?,?,?,?,?,?,?)";
    pdo()->prepare($sql)->execute([
      $b['name'],
      $b['username'],
      $b['password_plain'],
      $b['role'],
      $b['phone'] ?? null,
      $b['email'] ?? null,
      isset($b['is_active']) ? (int)$b['is_active'] : 1,
    ]);
    return (int)pdo()->lastInsertId();
  }

  public static function update(int $id, array $b) {
    $fields = [
      'name=?',
      'username=?',
      'role=?',
      'phone=?',
      'email=?',
      'is_active=?',
    ];
    $args = [
      $b['name'],
      $b['username'],
      $b['role'],
      $b['phone'] ?? null,
      $b['email'] ?? null,
      isset($b['is_active']) ? (int)$b['is_active'] : 1,
    ];
    if (!empty($b['password_plain'])) {
      $fields[] = 'password_plain=?';
      $args[] = $b['password_plain'];
    }
    $args[] = $id;
    $sql = 'UPDATE users SET ' . implode(',', $fields) . ' WHERE id=?';
    pdo()->prepare($sql)->execute($args);
  }

  public static function delete(int $id) {
    pdo()->prepare("DELETE FROM users WHERE id=?")->execute([$id]);
  }
}
