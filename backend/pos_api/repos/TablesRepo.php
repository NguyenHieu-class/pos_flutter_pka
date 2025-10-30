<?php
// repos/TablesRepo.php
require_once __DIR__ . '/../lib/db.php';

class TablesRepo {
  public static function areas() {
    return pdo()->query("SELECT * FROM areas ORDER BY sort, id")->fetchAll();
  }
  public static function tables($areaId=null, $status=null) {
    $sql = "SELECT dt.*, a.code AS area_code, a.name AS area_name
            FROM dining_tables dt
            JOIN areas a ON a.id=dt.area_id
            WHERE 1=1";
    $args=[];
    if ($areaId) { $sql.=" AND dt.area_id=?"; $args[]=(int)$areaId; }
    if ($status) { $sql.=" AND dt.status=?"; $args[]=$status; }
    $sql.=" ORDER BY a.sort, dt.number";
    $s = pdo()->prepare($sql); $s->execute($args); return $s->fetchAll();
  }
  public static function setStatus(int $tableId, string $status) {
    pdo()->prepare("UPDATE dining_tables SET status=? WHERE id=?")->execute([$status,$tableId]);
  }
}
