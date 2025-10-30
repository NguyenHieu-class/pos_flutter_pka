<?php
// config.php
date_default_timezone_set('Asia/Bangkok');

define('DB_DSN',  'mysql:host=localhost;dbname=pos;charset=utf8mb4');
define('DB_USER', 'root'); // đổi nếu bạn dùng user khác
define('DB_PASS', '');

define('BASE_PATH', __DIR__); // C:\\laragon\\www\\pos_api
define('UPLOAD_DIR', BASE_PATH . '/uploads');
define('ITEM_UPLOAD_DIR', UPLOAD_DIR . '/items');
define('CAT_UPLOAD_DIR',  UPLOAD_DIR . '/categories');
define('AREA_UPLOAD_DIR', UPLOAD_DIR . '/areas');
define('MOD_UPLOAD_DIR',  UPLOAD_DIR . '/modifiers');
define('STN_UPLOAD_DIR',  UPLOAD_DIR . '/stations');

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Headers: Authorization, Content-Type');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }
