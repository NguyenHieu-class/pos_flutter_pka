<?php
// controllers/AdminReceiptsController.php
require_once __DIR__ . '/../lib/http.php';
require_once __DIR__ . '/../lib/auth.php';
require_once __DIR__ . '/../repos/ReceiptsRepo.php';

class AdminReceiptsController {
  public static function list() {
    need_role(['admin','cashier']);
    $from=query('from'); $to=query('to'); $q=query('q');
    $page = max(1,(int)query('page',1));
    $size = max(1,min(100,(int)query('page_size',20)));
    $res = ReceiptsRepo::list($from,$to,$q,$page,$size);
    json_ok(['rows'=>$res['rows'],'meta'=>['page'=>$page,'page_size'=>$size,'total'=>$res['total']]]);
  }
  public static function get($id) {
    need_role(['admin','cashier']);
    $rec = ReceiptsRepo::get((int)$id);
    if (!$rec) json_err('NOT_FOUND','Receipt not found',[],404);
    json_ok($rec);
  }
}
