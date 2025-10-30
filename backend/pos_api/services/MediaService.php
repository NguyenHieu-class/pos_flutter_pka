<?php
// services/MediaService.php
require_once __DIR__ . '/../lib/media.php';
require_once __DIR__ . '/../repos/MediaRepo.php';

class MediaService {
  public static function saveUploaded(string $field, string $destDir): array {
    if (!isset($_FILES[$field]) || $_FILES[$field]['error'] !== UPLOAD_ERR_OK)
      json_err('UPLOAD_FAILED','No file or upload error',[],400);
    $f = $_FILES[$field];
    $ext = strtolower(pathinfo($f['name'], PATHINFO_EXTENSION));
    if (!in_array($ext, ['jpg','jpeg','png','webp'], true))
      json_err('VALIDATION_FAILED','Only jpg/jpeg/png/webp allowed',[],422);

    if (!is_dir($destDir)) { mkdir($destDir, 0777, true); }
    $base = pathinfo($f['name'], PATHINFO_FILENAME);
    $safe = sanitize_filename($base) . '-' . time() . '.' . $ext;

    // build relative & absolute
    $rel = str_replace(BASE_PATH.'/', '', $destDir.'/'. $safe);
    $abs = $destDir . '/' . $safe;

    if (!move_uploaded_file($f['tmp_name'], $abs))
      json_err('UPLOAD_FAILED','Cannot move file',[],500);

    $mediaId = MediaRepo::insertFile($rel, $f['type'] ?? null, (int)$f['size']);
    return ['media_id'=>$mediaId, 'path'=>$rel, 'url'=>build_url($rel)];
  }
}
