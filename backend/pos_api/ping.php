<?php
// ping.php
header('Content-Type: application/json; charset=utf-8');
date_default_timezone_set('Asia/Bangkok');
echo json_encode(['ok'=>true,'time'=>date('Y-m-d H:i:s'),'tz'=>date_default_timezone_get()]);
