<?php
// controllers/LogsController.php
require_once __DIR__ . '/../lib/http.php';
require_once __DIR__ . '/../lib/auth.php';
require_once __DIR__ . '/../repos/LogsRepo.php';

class LogsController {
  public static function audit() {
    need_role(['admin']);
    $rows = LogsRepo::audit([
      'user_id' => query('user_id'),
      'action' => query('action'),
      'entity' => query('entity'),
      'from' => query('from'),
      'to' => query('to'),
    ]);
    $data = array_map(function ($row) {
      return [
        'id' => (int)$row['id'],
        'user_id' => $row['user_id'] ? (int)$row['user_id'] : null,
        'user_name' => $row['user_name'],
        'action' => $row['action'],
        'entity' => $row['entity'],
        'entity_id' => $row['entity_id'] ? (int)$row['entity_id'] : null,
        'payload' => $row['payload'] ? json_decode($row['payload'], true) : null,
        'created_at' => $row['created_at'],
      ];
    }, $rows);
    json_ok($data);
  }

  public static function activity() {
    need_role(['admin']);
    $rows = LogsRepo::activity([
      'user_id' => query('user_id'),
      'scope' => query('scope'),
      'from' => query('from'),
      'to' => query('to'),
    ]);
    $data = array_map(function ($row) {
      return [
        'id' => (int)$row['id'],
        'user_id' => $row['user_id'] ? (int)$row['user_id'] : null,
        'user_name' => $row['user_name'],
        'scope' => $row['scope'],
        'message' => $row['message'],
        'ref_entity' => $row['ref_entity'],
        'ref_id' => $row['ref_id'] ? (int)$row['ref_id'] : null,
        'created_at' => $row['created_at'],
      ];
    }, $rows);
    json_ok($data);
  }
}
