<?php
// repos/ReceiptsRepo.php
require_once __DIR__ . '/../lib/db.php';

class ReceiptsRepo {
  public static function list($from=null, $to=null, $q=null, $page=1, $pageSize=20) {
    $where=" WHERE 1=1 "; $args=[];
    if ($from) { $where.=" AND paid_at >= ?"; $args[]=$from.' 00:00:00'; }
    if ($to)   { $where.=" AND paid_at <= ?"; $args[]=$to.' 23:59:59'; }
    if ($q)    { $where.=" AND (receipt_no LIKE ? OR table_code LIKE ? OR cashier_name LIKE ?)"; $args[]="%$q%"; $args[]="%$q%"; $args[]="%$q%"; }
    $cnt = pdo()->prepare("SELECT COUNT(*) FROM receipts $where"); $cnt->execute($args);
    $total = (int)$cnt->fetchColumn();
    $offset = ($page-1)*$pageSize;
    $s = pdo()->prepare("SELECT * FROM receipts $where ORDER BY paid_at DESC, id DESC LIMIT $pageSize OFFSET $offset");
    $s->execute($args);
    return ['rows'=>$s->fetchAll(),'total'=>$total];
  }

  public static function get(int $id) {
    $r = pdo()->prepare("SELECT * FROM receipts WHERE id=?"); $r->execute([$id]); $rec=$r->fetch();
    if (!$rec) return null;
    $i = pdo()->prepare("SELECT * FROM receipt_items WHERE receipt_id=? ORDER BY id");
    $i->execute([$id]); $rec['items'] = $i->fetchAll();
    return $rec;
  }
}
