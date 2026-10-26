<?php
// Explicit one-time replacement. Run only after a verified database backup.
if (PHP_SAPI !== 'cli') { http_response_code(404); exit; }
if (($argv[1] ?? '') !== '--apply') { fwrite(STDERR, 'Pass --apply after backing up the database.'.PHP_EOL); exit(1); }
$_SERVER['REQUEST_METHOD'] = 'CLI';
require_once __DIR__ . '/../lib/db.php';
$pdo = pdo();
$groups = [
  ['MAP1', 'Khu bàn ăn', ['B01'=>2,'B02'=>2,'B03'=>6,'B04'=>6,'B05'=>6,'B06'=>2,'B07'=>4,'B08'=>6,'B09'=>4]],
  ['MAP2', 'Phòng bao', ['P01'=>6,'A01'=>6,'A02'=>6,'A03'=>6,'A04'=>6,'A05'=>6,'A06'=>6,'A07'=>6,'A08'=>6,'A09'=>6,'A10'=>6]],
  ['MAP3', 'Sân vườn', ['S01'=>6,'S02'=>6,'S03'=>6,'S04'=>6,'S05'=>6,'S06'=>6,'S07'=>2,'S08'=>6,'S09'=>4,'S10'=>6]],
];
$links = [];
try {
  $pdo->beginTransaction();
  // Lock table rows so another request cannot start an order during replacement.
  $pdo->query('SELECT id FROM dining_tables FOR UPDATE')->fetchAll();
  $pdo->query('SELECT id FROM areas FOR UPDATE')->fetchAll();
  if ((int)$pdo->query("SELECT COUNT(*) FROM orders WHERE table_id IS NOT NULL AND status='open'")->fetchColumn() > 0) {
    throw new RuntimeException('Open table orders exist. Replacement stopped.');
  }
  if ((int)$pdo->query("SELECT COUNT(*) FROM areas WHERE code IN ('MAP1','MAP2','MAP3')")->fetchColumn() > 0) { throw new RuntimeException('Map areas already exist; refusing to repeat replacement.'); }
  $pdo->exec('DELETE FROM dining_tables');
  $pdo->exec('DELETE FROM areas');
  // Remove only image associations owned by the removed table/area entities.
  $pdo->exec("DELETE FROM entity_media WHERE entity_type IN ('table','area')");
  $areaInsert = $pdo->prepare('INSERT INTO areas(code,name,sort) VALUES(?,?,?)');
  $tableInsert = $pdo->prepare("INSERT INTO dining_tables(area_id,number,code,name,capacity,status,sort) VALUES(?,?,?,?,?,'free',?)");
  foreach ($groups as $map => [$code, $name, $tables]) {
    $areaInsert->execute([$code,$name,$map+1]);
    $areaId = (int)$pdo->lastInsertId();
    $number = 0;
    foreach ($tables as $tableCode => $capacity) {
      $number++;
      $tableInsert->execute([$areaId,$number,$tableCode,'Bàn '.$tableCode,$capacity,$number]);
      $links[$map.':'.$tableCode] = (int)$pdo->lastInsertId();
    }
  }
  $summary = $pdo->query('SELECT COUNT(*) AS tables_count,SUM(capacity) AS seats FROM dining_tables')->fetch();
  if ((int)$summary['tables_count'] !== 30 || (int)$summary['seats'] !== 158) {
    throw new RuntimeException('Map totals do not match.');
  }
  $pdo->commit();
  $output = __DIR__ . '/../../../assets/maps/table_links.json';
  if (file_put_contents($output, json_encode($links, JSON_PRETTY_PRINT|JSON_UNESCAPED_UNICODE)) === false) {
    throw new RuntimeException('Database committed but map link file could not be written.');
  }
  echo json_encode(['summary'=>$summary,'links'=>$links], JSON_PRETTY_PRINT|JSON_UNESCAPED_UNICODE), PHP_EOL;
} catch (Throwable $error) {
  if ($pdo->inTransaction()) $pdo->rollBack();
  fwrite(STDERR, $error->getMessage().PHP_EOL);
  exit(1);
}
