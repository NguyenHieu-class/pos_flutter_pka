<?php
// ============================================
// POS API - single file router (works with/without .htaccess)
// ============================================
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/lib/http.php';

// include controllers
require_once __DIR__ . '/controllers/AuthController.php';
require_once __DIR__ . '/controllers/CategoriesController.php';
require_once __DIR__ . '/controllers/ItemsController.php';
require_once __DIR__ . '/controllers/TablesController.php';
require_once __DIR__ . '/controllers/OrdersController.php';
require_once __DIR__ . '/controllers/KitchenController.php';
require_once __DIR__ . '/controllers/AdminReceiptsController.php';
require_once __DIR__ . '/controllers/UploadsController.php';
require_once __DIR__ . '/controllers/ModifiersController.php';

$method = $_SERVER['REQUEST_METHOD'];

// Robust path resolver: prefer PATH_INFO, else parse REQUEST_URI
$path = $_SERVER['PATH_INFO'] ?? null;
if ($path === null) {
  $uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH) ?? '/';
  $prefix = rtrim(dirname($_SERVER['SCRIPT_NAME']), '/'); // e.g. /pos_api
  if ($prefix && str_starts_with($uri, $prefix)) $uri = substr($uri, strlen($prefix));
  if (str_starts_with($uri, '/index.php')) $uri = substr($uri, strlen('/index.php'));
  $path = $uri === '' ? '/' : $uri;
}

// --- QUICK DIAG (uncomment if needed) ---
// file_put_contents(__DIR__.'/debug_path.log',
//   date('c')." METHOD=$method PATH='$path' URI=".$_SERVER['REQUEST_URI']."\n",
//   FILE_APPEND
// );

try {
  // PING direct
  if ($path === '/ping' || $path === '/ping.php' || $path === '/') {
    require __DIR__ . '/ping.php'; exit;
  }

  // ========== AUTH ==========
  if ($path === '/v1/auth/login' && $method === 'POST') return AuthController::login();

  // ========== CATEGORIES ==========
  if ($path === '/v1/categories' && $method === 'GET')  return CategoriesController::list();
  if ($path === '/v1/categories' && $method === 'POST') return CategoriesController::create();
  if (preg_match('#^/v1/categories/(\d+)$#',$path,$m)) {
    if ($method==='PUT')    return CategoriesController::update((int)$m[1]);
    if ($method==='DELETE') return CategoriesController::delete((int)$m[1]);
  }
  if (preg_match('#^/v1/categories/(\d+)/image$#',$path,$m) && $method==='POST')
    return CategoriesController::setImage((int)$m[1]);

  // ========== ITEMS ==========
  if ($path === '/v1/items' && $method==='GET')  return ItemsController::list();
  if ($path === '/v1/items' && $method==='POST') return ItemsController::create();
  if (preg_match('#^/v1/items/(\d+)$#',$path,$m) && $method==='GET') return ItemsController::get((int)$m[1]);
  if (preg_match('#^/v1/items/(\d+)$#',$path,$m) && $method==='PUT') return ItemsController::update((int)$m[1]);
  if (preg_match('#^/v1/items/(\d+)$#',$path,$m) && $method==='DELETE') return ItemsController::delete((int)$m[1]);
  if (preg_match('#^/v1/items/(\d+)/modifiers$#',$path,$m) && $method==='GET') return ItemsController::modifiers((int)$m[1]);
  if (preg_match('#^/v1/items/(\d+)/image$#',$path,$m) && $method==='POST') return ItemsController::setImage((int)$m[1]);

  // ========== MODIFIERS (ADMIN) ==========
  if ($path === '/v1/admin/modifier-groups' && $method==='GET') return ModifiersController::groups();
  if ($path === '/v1/admin/modifier-groups' && $method==='POST') return ModifiersController::createGroup();
  if (preg_match('#^/v1/admin/modifier-groups/(\d+)$#',$path,$m)) {
    if ($method==='PUT') return ModifiersController::updateGroup((int)$m[1]);
    if ($method==='DELETE') return ModifiersController::deleteGroup((int)$m[1]);
  }
  if (preg_match('#^/v1/admin/modifier-groups/(\d+)/options$#',$path,$m)) {
    if ($method==='GET') return ModifiersController::options((int)$m[1]);
    if ($method==='POST') return ModifiersController::createOption((int)$m[1]);
  }
  if (preg_match('#^/v1/admin/modifier-options/(\d+)$#',$path,$m)) {
    if ($method==='PUT') return ModifiersController::updateOption((int)$m[1]);
    if ($method==='DELETE') return ModifiersController::deleteOption((int)$m[1]);
  }
  if (preg_match('#^/v1/admin/items/(\d+)/modifier-groups$#',$path,$m)) {
    if ($method==='GET') return ModifiersController::itemGroups((int)$m[1]);
    if ($method==='PUT') return ModifiersController::setItemGroups((int)$m[1]);
  }

  // ========== AREAS & TABLES ==========
  if ($path === '/v1/areas' && $method==='GET')  return TablesController::areas();
  if ($path === '/v1/tables' && $method==='GET') return TablesController::tables();
  if (preg_match('#^/v1/tables/(\d+)/status$#',$path,$m) && $method==='PUT') return TablesController::setStatus((int)$m[1]);

  // ========== ORDERS ==========
  if ($path === '/v1/orders' && $method==='GET')  return OrdersController::list();
  if ($path === '/v1/orders' && $method==='POST') return OrdersController::create();
  if (preg_match('#^/v1/orders/(\d+)$#',$path,$m) && $method==='GET') return OrdersController::get((int)$m[1]);
  if (preg_match('#^/v1/orders/(\d+)/items$#',$path,$m) && $method==='POST') return OrdersController::addItem((int)$m[1]);
  if (preg_match('#^/v1/order-items/(\d+)$#',$path,$m) && $method==='PUT') return OrdersController::updateOrderItem((int)$m[1]);
  if (preg_match('#^/v1/order-items/(\d+)$#',$path,$m) && $method==='DELETE') return OrdersController::deleteOrderItem((int)$m[1]);
  if (preg_match('#^/v1/orders/(\d+)/checkout$#',$path,$m) && $method==='POST') return OrdersController::checkout((int)$m[1]);

  // ========== KITCHEN ==========
  if ($path === '/v1/kitchen/queue' && $method==='GET') return KitchenController::queue();
  if (preg_match('#^/v1/kitchen/items/(\d+)/status$#',$path,$m) && $method==='PUT') return KitchenController::setItemStatus((int)$m[1]);

  // ========== RECEIPTS (ADMIN) ==========
  if ($path === '/v1/admin/receipts' && $method==='GET') return AdminReceiptsController::list();
  if (preg_match('#^/v1/admin/receipts/(\d+)$#',$path,$m) && $method==='GET') return AdminReceiptsController::get((int)$m[1]);

  // ========== UPLOADS ==========
  if ($path === '/v1/uploads/items'      && $method==='POST') return UploadsController::uploadItem();
  if ($path === '/v1/uploads/categories' && $method==='POST') return UploadsController::uploadCategory();
  if ($path === '/v1/uploads/areas'      && $method==='POST') return UploadsController::uploadArea();
  if ($path === '/v1/uploads/modifiers'  && $method==='POST') return UploadsController::uploadModifier();
  if ($path === '/v1/uploads/stations'   && $method==='POST') return UploadsController::uploadStation();

  // fallback 404
  http_response_code(404);
  echo json_encode(['ok'=>false,'error'=>'NOT_FOUND','message'=>'Endpoint not found','details'=>['path'=>$path]], JSON_UNESCAPED_UNICODE);

} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode(['ok'=>false,'error'=>'SERVER_ERROR','message'=>$e->getMessage()]);
}
