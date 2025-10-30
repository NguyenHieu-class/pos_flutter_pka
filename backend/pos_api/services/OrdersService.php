<?php
// services/OrdersService.php
require_once __DIR__ . '/../lib/db.php';
require_once __DIR__ . '/../lib/util.php';
require_once __DIR__ . '/../repos/DiscountsRepo.php';

class OrdersService {
  public static function addItemWithModifiers(int $orderId, int $itemId, int $qty, ?string $note, array $modifierOptionIds): int {
    $s = pdo()->prepare("SELECT id,name,price,tax_rate,station_id FROM items WHERE id=? AND enabled=1");
    $s->execute([$itemId]); $item=$s->fetch();
    if (!$item) json_err('NOT_FOUND','Item not found',[],404);

    $delta = 0.0; $modsRows=[];
    if ($modifierOptionIds) {
      $in = implode(',', array_fill(0, count($modifierOptionIds), '?'));
      $m = pdo()->prepare("SELECT id,name,price_delta FROM modifier_options WHERE id IN ($in)");
      $m->execute($modifierOptionIds); $modsRows = $m->fetchAll();
      foreach ($modsRows as $r) $delta += (float)$r['price_delta'];
    }

    pdo()->prepare("INSERT INTO order_items(order_id,item_id,item_name,station_id,qty,unit_price,tax_rate,discount_amount,line_total,note,kitchen_status,created_at)
                    VALUES(?,?,?,?,?,?,?,?,?,?, 'queued', NOW())")
        ->execute([
          $orderId,$item['id'],$item['name'],$item['station_id'],$qty,$item['price'],$item['tax_rate'],0,
          ($item['price']+$delta)*$qty,$note
        ]);
    $oid = (int)pdo()->lastInsertId();

    if ($modsRows) {
      $ins = pdo()->prepare("INSERT INTO order_item_modifiers(order_item_id,option_id,option_name,unit_delta,qty) VALUES(?,?,?,?,1)");
      foreach ($modsRows as $r) $ins->execute([$oid,$r['id'],$r['name'],$r['price_delta']]);
    }
    return $oid;
  }

  public static function checkout(int $orderId, int $cashierId, array $payload) {
    $pdo = pdo(); $pdo->beginTransaction();
    try {
      $o = $pdo->prepare("SELECT * FROM orders WHERE id=? FOR UPDATE");
      $o->execute([$orderId]); $order=$o->fetch();
      if (!$order) { $pdo->rollBack(); json_err('NOT_FOUND','Order not found',[],404); }
      if ($order['status']!=='open') { $pdo->rollBack(); json_err('CONFLICT','Order not open'); }

      $subtotal = (float)$pdo->query("SELECT COALESCE(SUM(line_total),0) FROM order_items WHERE order_id=".$orderId)->fetchColumn();

      $discountPayload = $payload['discount'] ?? null;
      $discountTotal = 0.0;
      $discountSnapshot = null;
      if (is_array($discountPayload)) {
        if (isset($discountPayload['id'])) {
          $discountRow = DiscountsRepo::findActiveById((int)$discountPayload['id']);
          if (!$discountRow) {
            $pdo->rollBack();
            json_err('VALIDATION_FAILED', 'Mã giảm giá không hợp lệ', [], 422);
          }
          $minSubtotal = isset($discountRow['min_subtotal']) ? (float)$discountRow['min_subtotal'] : 0.0;
          if ($minSubtotal > 0 && $subtotal + 0.00001 < $minSubtotal) {
            $pdo->rollBack();
            json_err('VALIDATION_FAILED', 'Đơn hàng chưa đạt điều kiện áp dụng mã giảm giá', [], 422);
          }
          $discountTotal = (float)$discountRow['value'];
          if ($discountRow['type'] === 'percent') {
            $rate = max(0.0, min(100.0, (float)$discountRow['value']));
            $discountTotal = round($subtotal * $rate / 100, 2);
          }
          if ($discountTotal < 0) $discountTotal = 0;
          if ($discountTotal > $subtotal) $discountTotal = $subtotal;
          $discountSnapshot = [
            'discount_id' => (int)$discountRow['id'],
            'code' => $discountRow['code'],
            'name' => $discountRow['name'],
            'type' => $discountRow['type'],
            'value' => (float)$discountRow['value'],
            'amount' => $discountTotal,
          ];
        } elseif (isset($discountPayload['amount'])) {
          $discountTotal = max(0.0, (float)$discountPayload['amount']);
          if ($discountTotal > $subtotal) $discountTotal = $subtotal;
        }
      } else {
        $discountTotal = (float)($payload['discount_total'] ?? 0);
      }

      $tax     = (float)($payload['tax_total'] ?? 0);
      $service = (float)($payload['service_total'] ?? 0);
      $total   = $subtotal - $discountTotal + $tax + $service;
      if ($total < 0) {
        $total = 0;
      }

      $methods = $payload['payments'] ?? [['method'=>'cash','amount'=>$total]];
      $paidTxt=[];
      foreach ($methods as $pm) {
        $code=$pm['method']; $amt=(float)$pm['amount'];
        $mid=$pdo->prepare("SELECT id FROM payment_methods WHERE code=? AND enabled=1");
        $mid->execute([$code]); $midVal=$mid->fetchColumn();
        if (!$midVal) { $pdo->rollBack(); json_err('VALIDATION_FAILED','Invalid payment method: '.$code,[],422); }
        $pdo->prepare("INSERT INTO payments(order_id,method_id,amount,paid_at) VALUES(?,?,?,NOW())")
            ->execute([$orderId,$midVal,$amt]);
        $paidTxt[] = "$code:" . number_format($amt,0,'.','');
      }

      $pdo->prepare("UPDATE orders SET subtotal=?,discount_total=?,tax_total=?,service_total=?,total=?,status='closed',closed_by=?,closed_at=NOW(),note=? WHERE id=?")
          ->execute([$subtotal,$discountTotal,$tax,$service,$total,$cashierId,$payload['note'] ?? null,$orderId]);

      $pdo->prepare("DELETE FROM order_discounts WHERE order_id=?")
          ->execute([$orderId]);
      if ($discountSnapshot !== null) {
        $pdo->prepare("INSERT INTO order_discounts(order_id,discount_id,code,name,type,value,amount) VALUES(?,?,?,?,?,?,?)")
            ->execute([
              $orderId,
              $discountSnapshot['discount_id'],
              $discountSnapshot['code'],
              $discountSnapshot['name'],
              $discountSnapshot['type'],
              $discountSnapshot['value'],
              $discountSnapshot['amount'],
            ]);
      }

      $pdo->prepare("UPDATE dining_tables SET status='cleaning' WHERE id=(SELECT table_id FROM orders WHERE id=?)")
          ->execute([$orderId]);

      $pos = $pdo->prepare("SELECT t.code table_code, a.code area_code
                            FROM orders o
                            LEFT JOIN dining_tables t ON t.id=o.table_id
                            LEFT JOIN areas a ON a.id=t.area_id WHERE o.id=?");
      $pos->execute([$orderId]); $x=$pos->fetch();

      $u = $pdo->prepare("SELECT name FROM users WHERE id=?"); $u->execute([$cashierId]); $cashierName=$u->fetchColumn() ?: 'N/A';
      $receiptNo = make_receipt_no($orderId);

      $pdo->prepare("INSERT INTO receipts(order_id,receipt_no,table_code,area_code,cashier_id,cashier_name,customer_name,
                      subtotal,discount_total,tax_total,service_total,total,paid_methods,paid_at,note)
                     VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)")
          ->execute([
            $orderId,$receiptNo,$x['table_code'] ?? null,$x['area_code'] ?? null,$cashierId,$cashierName,$order['customer_name'] ?? null,
            $subtotal,$discountTotal,$tax,$service,$total,implode(',',$paidTxt),date('Y-m-d H:i:s'),$payload['note'] ?? null
          ]);
      $rid=(int)$pdo->lastInsertId();

      $oi = $pdo->prepare("SELECT id,item_name,qty,unit_price,line_total FROM order_items WHERE order_id=? ORDER BY id");
      $oi->execute([$orderId]);
      $ins = $pdo->prepare("INSERT INTO receipt_items(receipt_id,item_name,qty,unit_price,modifiers_text,line_total) VALUES(?,?,?,?,?,?)");
      foreach ($oi->fetchAll() as $row) {
        $mods = $pdo->prepare("SELECT option_name, unit_delta, qty FROM order_item_modifiers WHERE order_item_id=?");
        $mods->execute([$row['id']]);
        $parts=[];
        foreach ($mods->fetchAll() as $m) {
          $t=$m['option_name'];
          if ((float)$m['unit_delta']!=0) $t.='(+'.number_format($m['unit_delta'],0).')';
          if ((int)$m['qty']>1) $t.=' x'.$m['qty'];
          $parts[]=$t;
        }
        $ins->execute([$rid,$row['item_name'],$row['qty'],$row['unit_price'],implode('; ',$parts),$row['line_total']]);
      }

      $pdo->commit();
      return ['receipt'=>[
        'id'=>$rid,'receipt_no'=>$receiptNo,'table_code'=>$x['table_code'] ?? null,'area_code'=>$x['area_code'] ?? null,
        'subtotal'=>$subtotal,'discount_total'=>$discountTotal,'tax_total'=>$tax,'service_total'=>$service,'total'=>$total,
        'paid_methods'=>implode(',',$paidTxt),'paid_at'=>date('Y-m-d H:i:s')
      ]];
    } catch (Throwable $e) { $pdo->rollBack(); json_err('SERVER_ERROR',$e->getMessage(),[],500); }
  }
}
