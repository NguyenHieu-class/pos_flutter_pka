<?php
// repos/UsersRepo.php
require_once __DIR__ . '/../lib/db.php';

class UsersRepo {
  public static function findByUsername(string $username) {
    $s = pdo()->prepare("SELECT * FROM users WHERE username=?");
    $s->execute([$username]); return $s->fetch();
  }
}
