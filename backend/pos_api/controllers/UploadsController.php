<?php
// controllers/UploadsController.php
require_once __DIR__ . '/../lib/http.php';
require_once __DIR__ . '/../lib/auth.php';
require_once __DIR__ . '/../services/MediaService.php';
require_once __DIR__ . '/../repos/MediaRepo.php';

class UploadsController {
  public static function uploadItem()      { need_role(['admin']); json_ok(MediaService::saveUploaded('file', ITEM_UPLOAD_DIR),201); }
  public static function uploadCategory()  { need_role(['admin']); json_ok(MediaService::saveUploaded('file', CAT_UPLOAD_DIR), 201); }
  public static function uploadArea()      { need_role(['admin']); json_ok(MediaService::saveUploaded('file', AREA_UPLOAD_DIR),201); }
  public static function uploadModifier()  { need_role(['admin']); json_ok(MediaService::saveUploaded('file', MOD_UPLOAD_DIR), 201); }
  public static function uploadStation()   { need_role(['admin']); json_ok(MediaService::saveUploaded('file', STN_UPLOAD_DIR), 201); }
}
