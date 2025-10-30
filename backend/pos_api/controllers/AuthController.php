<?php
// controllers/AuthController.php
require_once __DIR__ . '/../lib/http.php';
require_once __DIR__ . '/../lib/auth.php';
require_once __DIR__ . '/../repos/UsersRepo.php';

class AuthController {
  public static function login() {
    $b = input_json(); require_fields($b, ['username','password']);
    $u = UsersRepo::findByUsername($b['username']);
    if (!$u || !$u['is_active'] || $u['password_plain'] !== $b['password']) {
      json_err('INVALID_CREDENTIAL','Username or password is incorrect',[],401);
    }
    $token = make_token((int)$u['id'], $u['role']);
    json_ok(['token'=>$token, 'user'=>['id'=>$u['id'],'name'=>$u['name'],'role'=>$u['role']]]);
  }
}
