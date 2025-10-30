<?php
// repos/LogsRepo.php
require_once __DIR__ . '/../lib/db.php';

class LogsRepo {
  public static function audit(array $filters = []): array {
    $sql = "SELECT al.*, u.name AS user_name
            FROM audit_logs al
            LEFT JOIN users u ON u.id = al.user_id
            WHERE 1=1";
    $args = [];
    if (!empty($filters['user_id'])) {
      $sql .= " AND al.user_id=?";
      $args[] = (int)$filters['user_id'];
    }
    if (!empty($filters['action'])) {
      $sql .= " AND al.action=?";
      $args[] = $filters['action'];
    }
    if (!empty($filters['entity'])) {
      $sql .= " AND al.entity=?";
      $args[] = $filters['entity'];
    }
    if (!empty($filters['from'])) {
      $sql .= " AND al.created_at>=?";
      $args[] = $filters['from'];
    }
    if (!empty($filters['to'])) {
      $sql .= " AND al.created_at<=?";
      $args[] = $filters['to'];
    }
    $sql .= " ORDER BY al.created_at DESC LIMIT 500";
    $stmt = pdo()->prepare($sql);
    $stmt->execute($args);
    return $stmt->fetchAll();
  }

  public static function activity(array $filters = []): array {
    $sql = "SELECT al.*, u.name AS user_name
            FROM activity_logs al
            LEFT JOIN users u ON u.id = al.user_id
            WHERE 1=1";
    $args = [];
    if (!empty($filters['user_id'])) {
      $sql .= " AND al.user_id=?";
      $args[] = (int)$filters['user_id'];
    }
    if (!empty($filters['scope'])) {
      $sql .= " AND al.scope=?";
      $args[] = $filters['scope'];
    }
    if (!empty($filters['from'])) {
      $sql .= " AND al.created_at>=?";
      $args[] = $filters['from'];
    }
    if (!empty($filters['to'])) {
      $sql .= " AND al.created_at<=?";
      $args[] = $filters['to'];
    }
    $sql .= " ORDER BY al.created_at DESC LIMIT 500";
    $stmt = pdo()->prepare($sql);
    $stmt->execute($args);
    return $stmt->fetchAll();
  }
}
