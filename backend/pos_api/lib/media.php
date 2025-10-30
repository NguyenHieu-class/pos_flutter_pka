<?php
// lib/media.php
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/db.php';

function base_url_prefix(): string {
  // http://host/pos_api (không dấu / ở cuối)
  $host = $_SERVER['HTTP_HOST'] ?? 'localhost';
  return (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https://' : 'http://') . $host . '/pos_api';
}

function build_url(?string $rel): ?string {
  if (!$rel) return null;
  return rtrim(base_url_prefix(), '/') . '/' . ltrim($rel, '/');
}

function primary_media_map(string $entity, array $ids): array {
  if (!$ids) return [];
  $in = implode(',', array_fill(0, count($ids), '?'));
  $sql = "SELECT em.entity_id, mf.path
          FROM entity_media em
          JOIN media_files mf ON mf.id = em.media_id
          WHERE em.entity_type=? AND em.role='primary' AND em.entity_id IN ($in)";
  $stmt = pdo()->prepare($sql);
  $stmt->execute(array_merge([$entity], $ids));
  $map = [];
  foreach ($stmt->fetchAll() as $r) $map[(int)$r['entity_id']] = $r['path'];
  return $map;
}

function resolve_item_image(array $row, array $primaryMap): ?string {
  $id = (int)$row['id'];
  $path = $primaryMap[$id] ?? $row['image_path'] ?? null;
  return build_url($path);
}

function resolve_category_image(array $row, array $primaryMap): ?string {
  $id = (int)$row['id'];
  $path = $primaryMap[$id] ?? $row['image_path'] ?? null;
  return build_url($path);
}

function resolve_category_banner(array $row): ?string {
  return build_url($row['banner_path'] ?? null);
}

function resolve_area_image(array $row, array $primaryMap): ?string {
  $id = (int)$row['id'];
  $path = $primaryMap[$id] ?? $row['image_path'] ?? null;
  return build_url($path);
}
