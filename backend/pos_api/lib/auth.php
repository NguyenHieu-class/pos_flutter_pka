<?php
// lib/auth.php
require_once __DIR__ . '/db.php';
require_once __DIR__ . '/http.php';

function make_token(int $uid, string $role): string {
  return $uid . '|' . $role . '|' . time(); // token đơn giản theo yêu cầu
}

function parse_token(?string $hdr): ?array {
  if (!$hdr) return null;
  if (stripos($hdr, 'Bearer ') === 0) $hdr = substr($hdr, 7);
  $parts = explode('|', $hdr);
  if (count($parts) < 3) return null;
  return ['uid' => (int)$parts[0], 'role' => $parts[1]];
}

function need_auth(): array {
  $auth = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
  $t = parse_token($auth);
  if (!$t) json_err('UNAUTHORIZED', 'Missing or invalid token', [], 401);
  $stmt = pdo()->prepare("SELECT id, name, role, is_active FROM users WHERE id=?");
  $stmt->execute([$t['uid']]); $u = $stmt->fetch();
  if (!$u || !$u['is_active']) json_err('UNAUTHORIZED', 'User inactive', [], 401);
  return $u;
}

function need_role(array $roles): array {
  $u = need_auth();
  if (!in_array($u['role'], $roles, true)) json_err('FORBIDDEN', 'Insufficient role', [], 403);
  return $u;
}
