<?php
// controllers/AdminUsersController.php
require_once __DIR__ . '/../lib/http.php';
require_once __DIR__ . '/../lib/auth.php';
require_once __DIR__ . '/../repos/UsersRepo.php';

class AdminUsersController {
  private static function ensureManageableRole(string $role) {
    if (!in_array($role, ['cashier', 'kitchen'], true)) {
      json_err('VALIDATION_FAILED', 'Chỉ quản lý được người dùng thu ngân hoặc bếp', ['field' => 'role'], 422);
    }
  }

  private static function sanitize(array $row): array {
    return [
      'id' => (int)$row['id'],
      'name' => $row['name'],
      'username' => $row['username'],
      'role' => $row['role'],
      'phone' => $row['phone'],
      'email' => $row['email'],
      'is_active' => (int)$row['is_active'] === 1,
      'created_at' => $row['created_at'] ?? null,
      'updated_at' => $row['updated_at'] ?? null,
    ];
  }

  public static function list() {
    need_role(['admin']);
    $roleParam = $_GET['role'] ?? '';
    $roles = array_filter(array_map('trim', explode(',', $roleParam)));
    if (empty($roles)) {
      $roles = ['cashier', 'kitchen'];
    }
    $rows = UsersRepo::list($roles);
    $data = array_map(fn($row) => self::sanitize($row), $rows);
    json_ok($data);
  }

  public static function create() {
    need_role(['admin']);
    $b = input_json();
    require_fields($b, ['name', 'username', 'password', 'role']);
    self::ensureManageableRole($b['role']);
    $payload = [
      'name' => $b['name'],
      'username' => $b['username'],
      'password_plain' => $b['password'],
      'role' => $b['role'],
      'phone' => $b['phone'] ?? null,
      'email' => $b['email'] ?? null,
      'is_active' => isset($b['is_active']) ? (int)$b['is_active'] : 1,
    ];
    try {
      $id = UsersRepo::insert($payload);
    } catch (PDOException $e) {
      if ($e->getCode() === '23000') {
        json_err('DUPLICATE_USERNAME', 'Tên đăng nhập đã tồn tại', ['field' => 'username'], 409);
      }
      throw $e;
    }
    $user = UsersRepo::get($id);
    json_ok(self::sanitize($user), 201);
  }

  public static function update($id) {
    need_role(['admin']);
    $b = input_json();
    require_fields($b, ['name', 'username', 'role']);
    self::ensureManageableRole($b['role']);
    $payload = [
      'name' => $b['name'],
      'username' => $b['username'],
      'role' => $b['role'],
      'phone' => $b['phone'] ?? null,
      'email' => $b['email'] ?? null,
      'is_active' => isset($b['is_active']) ? (int)$b['is_active'] : 1,
    ];
    if (!empty($b['password'])) {
      $payload['password_plain'] = $b['password'];
    }
    try {
      UsersRepo::update((int)$id, $payload);
    } catch (PDOException $e) {
      if ($e->getCode() === '23000') {
        json_err('DUPLICATE_USERNAME', 'Tên đăng nhập đã tồn tại', ['field' => 'username'], 409);
      }
      throw $e;
    }
    $user = UsersRepo::get((int)$id);
    if (!$user) {
      json_err('NOT_FOUND', 'User not found', [], 404);
    }
    json_ok(self::sanitize($user));
  }

  public static function delete($id) {
    need_role(['admin']);
    $user = UsersRepo::get((int)$id);
    if (!$user) {
      json_err('NOT_FOUND', 'User not found', [], 404);
    }
    self::ensureManageableRole($user['role']);
    try {
      UsersRepo::delete((int)$id);
      json_ok(['id' => (int)$id, 'deleted' => true]);
    } catch (PDOException $e) {
      if ($e->getCode() === '23000') {
        UsersRepo::setActive((int)$id, false);
        json_ok(['id' => (int)$id, 'deleted' => false, 'is_active' => false]);
      }
      throw $e;
    }
  }
}
