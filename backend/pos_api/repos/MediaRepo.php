<?php
// repos/MediaRepo.php
require_once __DIR__ . '/../lib/db.php';

class MediaRepo {
  public static function insertFile(string $relPath, ?string $mime, int $bytes): int {
    $s = pdo()->prepare("INSERT INTO media_files(path, mime_type, bytes) VALUES(?,?,?)");
    $s->execute([$relPath, $mime, $bytes]);
    return (int)pdo()->lastInsertId();
  }

  public static function setPrimary(string $entity, int $entityId, int $mediaId, string $role='primary') {
    $pdo = pdo();
    $pdo->beginTransaction();
    try {
      $pdo->prepare("DELETE FROM entity_media WHERE entity_type=? AND entity_id=? AND role=?")
          ->execute([$entity, $entityId, $role]);
      $pdo->prepare("INSERT INTO entity_media(entity_type, entity_id, media_id, role, sort) VALUES(?,?,?,?,0)")
          ->execute([$entity, $entityId, $mediaId, $role]);
      $pdo->commit();
    } catch (Throwable $e) {
      $pdo->rollBack(); throw $e;
    }
  }
}
