<?php
// controllers/OrdersController.php
require_once __DIR__ . '/../lib/http.php';
require_once __DIR__ . '/../lib/auth.php';
require_once __DIR__ . '/../repos/OrdersRepo.php';
require_once __DIR__ . '/../repos/TablesRepo.php';
require_once __DIR__ . '/../services/OrdersService.php';

class OrdersController {
  public static function list() {
    need_role(['admin','cashier']);
    $statusParam = $_GET['status'] ?? 'open';
    $statusParam = is_string($statusParam) ? strtolower(trim($statusParam)) : 'open';
    $allowed = ['open', 'closed', 'cancelled'];
    if ($statusParam === 'all' || $statusParam === '') {
      $status = null;
    } elseif (in_array($statusParam, $allowed, true)) {
      $status = $statusParam;
    } else {
      $status = 'open';
    }
    $orders = OrdersRepo::listOrders($status);
    json_ok($orders);
  }

  public static function create() {
    $u = need_role(['admin','cashier']);
    $b = input_json(); require_fields($b, ['table_id']);
    $tableId = (int)$b['table_id'];
    if (OrdersRepo::findOpenByTable($tableId)) json_err('CONFLICT_OPEN_ORDER','Table already has an open order',[],409);
    $orderId = OrdersRepo::createOrder($tableId, (int)$u['id'], $b['customer_name'] ?? null);
    TablesRepo::setStatus($tableId, 'occupied');
    json_ok(['order_id'=>$orderId], 201);
  }

  public static function get($id) {
    $o = OrdersRepo::getOrderFull((int)$id);
    if (!$o) json_err('NOT_FOUND','Order not found',[],404);
    json_ok($o);
  }

  public static function addItem($id) {
    need_role(['admin','cashier']);
    $b = input_json(); require_fields($b, ['item_id','qty']);
    $mods = isset($b['modifiers']) && is_array($b['modifiers']) ? array_map('intval', $b['modifiers']) : [];
    $orderItemId = OrdersService::addItemWithModifiers((int)$id, (int)$b['item_id'], (int)$b['qty'], $b['note'] ?? null, $mods);
    json_ok(['order_item_id'=>$orderItemId], 201);
  }

  public static function updateOrderItem($orderItemId) {
    need_role(['admin','cashier']);
    $pdo = pdo();
    $row = $pdo->prepare("SELECT * FROM order_items WHERE id=?"); $row->execute([(int)$orderItemId]); $oi=$row->fetch();
    if (!$oi) json_err('NOT_FOUND','Order item not found',[],404);
    if ($oi['kitchen_status'] !== 'queued') json_err('CONFLICT','Cannot modify when already in kitchen',[],409);

    $b = input_json();
    $qty = isset($b['qty']) ? max(1,(int)$b['qty']) : (int)$oi['qty']; $note = array_key_exists('note',$b) ? $b['note'] : $oi['note'];

    $pdo->beginTransaction();
    try {
      if (isset($b['modifiers'])) {
        $mods = is_array($b['modifiers']) ? array_map('intval',$b['modifiers']) : [];
        $pdo->prepare("DELETE FROM order_item_modifiers WHERE order_item_id=?")->execute([(int)$orderItemId]);
        $delta = 0.0;
        if ($mods) {
          $in = implode(',', array_fill(0, count($mods), '?'));
          $m = $pdo->prepare("SELECT id,name,price_delta FROM modifier_options WHERE id IN ($in)");
          $m->execute($mods);
          $ins=$pdo->prepare("INSERT INTO order_item_modifiers(order_item_id,option_id,option_name,unit_delta,qty) VALUES(?,?,?,?,1)");
          foreach ($m->fetchAll() as $r) { $ins->execute([(int)$orderItemId,$r['id'],$r['name'],$r['price_delta']]); $delta += (float)$r['price_delta']; }
        }
        $unitEff = (float)$oi['unit_price'] + $delta;
        $line = $unitEff * $qty - (float)$oi['discount_amount'];
        $pdo->prepare("UPDATE order_items SET qty=?, note=?, line_total=?, updated_at=NOW() WHERE id=?")
            ->execute([$qty,$note,$line,(int)$orderItemId]);
      } else {
        $m = $pdo->prepare("SELECT COALESCE(SUM(unit_delta),0) FROM order_item_modifiers WHERE order_item_id=?");
        $m->execute([(int)$orderItemId]); $delta=(float)$m->fetchColumn();
        $unitEff = (float)$oi['unit_price'] + $delta;
        $line = $unitEff * $qty - (float)$oi['discount_amount'];
        $pdo->prepare("UPDATE order_items SET qty=?, note=?, line_total=?, updated_at=NOW() WHERE id=?")
            ->execute([$qty,$note,$line,(int)$orderItemId]);
      }
      $pdo->commit(); json_ok(['order_item_id'=>(int)$orderItemId,'qty'=>$qty,'note'=>$note]);
    } catch (Throwable $e) { $pdo->rollBack(); json_err('SERVER_ERROR',$e->getMessage(),[],500); }
  }

  public static function deleteOrderItem($orderItemId) {
    need_role(['admin','cashier']);
    $row = pdo()->prepare("SELECT kitchen_status FROM order_items WHERE id=?");
    $row->execute([(int)$orderItemId]); $st=$row->fetchColumn();
    if ($st===false) json_err('NOT_FOUND','Order item not found',[],404);
    if ($st!=='queued') json_err('CONFLICT','Cannot delete when already in kitchen',[],409);
    pdo()->prepare("DELETE FROM order_item_modifiers WHERE order_item_id=?")->execute([(int)$orderItemId]);
    pdo()->prepare("DELETE FROM order_items WHERE id=?")->execute([(int)$orderItemId]);
    json_ok(['deleted'=>(int)$orderItemId]);
  }

  public static function cancel($id) {
    $u = need_role(['admin','cashier']);
    $b = input_json();
    $pdo = pdo();
    $pdo->beginTransaction();
    try {
      $stmt = $pdo->prepare("SELECT * FROM orders WHERE id=? FOR UPDATE");
      $stmt->execute([(int)$id]);
      $order = $stmt->fetch();
      if (!$order) {
        $pdo->rollBack();
        json_err('NOT_FOUND', 'Order not found', [], 404);
      }
      if ($order['status'] !== 'open') {
        $pdo->rollBack();
        json_err('CONFLICT', 'Order is not open', [], 409);
      }
      $pdo->prepare("UPDATE orders SET status='cancelled', closed_by=?, closed_at=NOW(), note=COALESCE(?, note) WHERE id=?")
          ->execute([(int)$u['id'], $b['note'] ?? null, (int)$id]);
      if (!empty($order['table_id'])) {
        $pdo->prepare("UPDATE dining_tables SET status='free' WHERE id=?")
            ->execute([(int)$order['table_id']]);
      }
      $pdo->prepare("UPDATE order_items SET kitchen_status='cancelled' WHERE order_id=? AND kitchen_status IN ('queued','preparing')")
          ->execute([(int)$id]);
      $pdo->prepare("INSERT INTO order_cancellations(order_id,user_id,reason_id,note) VALUES(?,?,?,?)")
          ->execute([
            (int)$id,
            (int)$u['id'],
            isset($b['reason_id']) && $b['reason_id'] !== null ? (int)$b['reason_id'] : null,
            $b['note'] ?? null,
          ]);
      $pdo->commit();
      json_ok(['order_id' => (int)$id, 'status' => 'cancelled']);
    } catch (Throwable $e) {
      $pdo->rollBack();
      json_err('SERVER_ERROR', $e->getMessage(), [], 500);
    }
  }

  public static function checkout($id) {
    $u = need_role(['admin','cashier']);
    $b = input_json();
    $r = OrdersService::checkout((int)$id, (int)$u['id'], $b);
    json_ok($r);
  }
}
