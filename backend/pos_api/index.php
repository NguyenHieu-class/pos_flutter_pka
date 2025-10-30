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
require_once __DIR__ . '/controllers/AdminUsersController.php';
require_once __DIR__ . '/controllers/UploadsController.php';
require_once __DIR__ . '/controllers/ModifiersController.php';
require_once __DIR__ . '/controllers/ReasonCodesController.php';
require_once __DIR__ . '/controllers/KitchenStationsController.php';
require_once __DIR__ . '/controllers/InventoryController.php';
require_once __DIR__ . '/controllers/DiscountsController.php';
require_once __DIR__ . '/controllers/PaymentMethodsController.php';
require_once __DIR__ . '/controllers/ShiftsController.php';
require_once __DIR__ . '/controllers/ReportsController.php';
require_once __DIR__ . '/controllers/LogsController.php';
require_once __DIR__ . '/controllers/ToolsController.php';

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
  if (preg_match('#^/v1/categories/(\\d+)$#',$path,$m)) {
    if ($method==='PUT')    return CategoriesController::update((int)$m[1]);
    if ($method==='DELETE') return CategoriesController::delete((int)$m[1]);
  }
  if (preg_match('#^/v1/categories/(\\d+)/image$#',$path,$m) && $method==='POST')
    return CategoriesController::setImage((int)$m[1]);

  // ========== ITEMS ==========
  if ($path === '/v1/items' && $method==='GET')  return ItemsController::list();
  if ($path === '/v1/items' && $method==='POST') return ItemsController::create();
  if (preg_match('#^/v1/items/(\\d+)$#',$path,$m) && $method==='GET') return ItemsController::get((int)$m[1]);
  if (preg_match('#^/v1/items/(\\d+)$#',$path,$m) && $method==='PUT') return ItemsController::update((int)$m[1]);
  if (preg_match('#^/v1/items/(\\d+)$#',$path,$m) && $method==='DELETE') return ItemsController::delete((int)$m[1]);
  if (preg_match('#^/v1/items/(\\d+)/modifiers$#',$path,$m) && $method==='GET') return ItemsController::modifiers((int)$m[1]);
  if (preg_match('#^/v1/items/(\\d+)/image$#',$path,$m) && $method==='POST') return ItemsController::setImage((int)$m[1]);

  // ========== MODIFIERS (ADMIN) ==========
  if ($path === '/v1/admin/modifier-groups' && $method==='GET') return ModifiersController::groups();
  if ($path === '/v1/admin/modifier-groups' && $method==='POST') return ModifiersController::createGroup();
  if (preg_match('#^/v1/admin/modifier-groups/(\\d+)$#',$path,$m)) {
    if ($method==='PUT') return ModifiersController::updateGroup((int)$m[1]);
    if ($method==='DELETE') return ModifiersController::deleteGroup((int)$m[1]);
  }
  if (preg_match('#^/v1/admin/modifier-groups/(\\d+)/options$#',$path,$m)) {
    if ($method==='GET') return ModifiersController::options((int)$m[1]);
    if ($method==='POST') return ModifiersController::createOption((int)$m[1]);
  }
  if (preg_match('#^/v1/admin/modifier-options/(\\d+)$#',$path,$m)) {
    if ($method==='PUT') return ModifiersController::updateOption((int)$m[1]);
    if ($method==='DELETE') return ModifiersController::deleteOption((int)$m[1]);
  }
  if (preg_match('#^/v1/admin/items/(\\d+)/modifier-groups$#',$path,$m)) {
    if ($method==='GET') return ModifiersController::itemGroups((int)$m[1]);
    if ($method==='PUT') return ModifiersController::setItemGroups((int)$m[1]);
  }

  // ========== AREAS & TABLES ==========
  if ($path === '/v1/areas' && $method==='GET')  return TablesController::areas();
  if ($path === '/v1/areas' && $method==='POST') return TablesController::createArea();
  if (preg_match('#^/v1/areas/(\\d+)$#',$path,$m)) {
    if ($method==='PUT')    return TablesController::updateArea((int)$m[1]);
    if ($method==='DELETE') return TablesController::deleteArea((int)$m[1]);
  }
  if (preg_match('#^/v1/areas/(\\d+)/image$#',$path,$m) && $method==='POST')
    return TablesController::setAreaImage((int)$m[1]);

  if ($path === '/v1/tables' && $method==='GET') return TablesController::tables();
  if ($path === '/v1/tables' && $method==='POST') return TablesController::createTable();
  if (preg_match('#^/v1/tables/(\\d+)$#',$path,$m)) {
    if ($method==='PUT')    return TablesController::updateTable((int)$m[1]);
    if ($method==='DELETE') return TablesController::deleteTable((int)$m[1]);
  }
  if (preg_match('#^/v1/tables/(\\d+)/status$#',$path,$m) && $method==='PUT') return TablesController::setStatus((int)$m[1]);

  // ========== ORDERS ==========
  if ($path === '/v1/orders' && $method==='GET')  return OrdersController::list();
  if ($path === '/v1/orders' && $method==='POST') return OrdersController::create();
  if (preg_match('#^/v1/orders/(\\d+)$#',$path,$m) && $method==='GET') return OrdersController::get((int)$m[1]);
  if (preg_match('#^/v1/orders/(\\d+)/items$#',$path,$m) && $method==='POST') return OrdersController::addItem((int)$m[1]);
  if (preg_match('#^/v1/order-items/(\\d+)$#',$path,$m) && $method==='PUT') return OrdersController::updateOrderItem((int)$m[1]);
  if (preg_match('#^/v1/order-items/(\\d+)$#',$path,$m) && $method==='DELETE') return OrdersController::deleteOrderItem((int)$m[1]);
  if (preg_match('#^/v1/orders/(\\d+)/checkout$#',$path,$m) && $method==='POST') return OrdersController::checkout((int)$m[1]);
  if (preg_match('#^/v1/orders/(\\d+)/cancel$#',$path,$m) && $method==='POST') return OrdersController::cancel((int)$m[1]);

  // ========== KITCHEN ==========
  if ($path === '/v1/kitchen/queue' && $method==='GET') return KitchenController::queue();
  if ($path === '/v1/kitchen/history' && $method==='GET') return KitchenController::history();
  if (preg_match('#^/v1/kitchen/items/(\\d+)/status$#',$path,$m) && $method==='PUT') return KitchenController::setItemStatus((int)$m[1]);

  // ========== RECEIPTS (ADMIN) ==========
  if ($path === '/v1/admin/receipts' && $method==='GET') return AdminReceiptsController::list();
  if (preg_match('#^/v1/admin/receipts/(\\d+)$#',$path,$m) && $method==='GET') return AdminReceiptsController::get((int)$m[1]);

  // ========== USERS (ADMIN) ==========
  if ($path === '/v1/admin/users' && $method==='GET') return AdminUsersController::list();
  if ($path === '/v1/admin/users' && $method==='POST') return AdminUsersController::create();
  if (preg_match('#^/v1/admin/users/(\\d+)$#',$path,$m)) {
    if ($method==='PUT') return AdminUsersController::update((int)$m[1]);
    if ($method==='DELETE') return AdminUsersController::delete((int)$m[1]);
  }

  // ========== UPLOADS ==========
  if ($path === '/v1/uploads/items'      && $method==='POST') return UploadsController::uploadItem();
  if ($path === '/v1/uploads/categories' && $method==='POST') return UploadsController::uploadCategory();
  if ($path === '/v1/uploads/areas'      && $method==='POST') return UploadsController::uploadArea();
  if ($path === '/v1/uploads/modifiers'  && $method==='POST') return UploadsController::uploadModifier();
  if ($path === '/v1/uploads/stations'   && $method==='POST') return UploadsController::uploadStation();

  // ========== REASON CODES ==========
  if ($path === '/v1/admin/reason-codes' && $method==='GET') return ReasonCodesController::list();
  if ($path === '/v1/admin/reason-codes' && $method==='POST') return ReasonCodesController::create();
  if (preg_match('#^/v1/admin/reason-codes/(\\d+)$#',$path,$m)) {
    if ($method==='PUT') return ReasonCodesController::update((int)$m[1]);
    if ($method==='DELETE') return ReasonCodesController::delete((int)$m[1]);
  }

  // ========== KITCHEN STATIONS ==========
  if ($path === '/v1/admin/stations' && $method==='GET') return KitchenStationsController::list();
  if ($path === '/v1/admin/stations' && $method==='POST') return KitchenStationsController::create();
  if (preg_match('#^/v1/admin/stations/(\\d+)$#',$path,$m)) {
    if ($method==='PUT') return KitchenStationsController::update((int)$m[1]);
    if ($method==='DELETE') return KitchenStationsController::delete((int)$m[1]);
  }
  if (preg_match('#^/v1/admin/stations/(\\d+)/icon$#',$path,$m) && $method==='POST')
    return KitchenStationsController::setIcon((int)$m[1]);

  // ========== INVENTORY ==========
  if ($path === '/v1/admin/ingredients' && $method==='GET') return InventoryController::ingredients();
  if ($path === '/v1/admin/ingredients' && $method==='POST') return InventoryController::createIngredient();
  if (preg_match('#^/v1/admin/ingredients/(\\d+)$#',$path,$m)) {
    if ($method==='PUT') return InventoryController::updateIngredient((int)$m[1]);
    if ($method==='DELETE') return InventoryController::deleteIngredient((int)$m[1]);
  }
  if (preg_match('#^/v1/admin/items/(\\d+)/recipe$#',$path,$m)) {
    if ($method==='GET') return InventoryController::getRecipe((int)$m[1]);
    if ($method==='PUT') return InventoryController::setRecipe((int)$m[1]);
  }
  if ($path === '/v1/admin/stock-moves' && $method==='GET') return InventoryController::stockMoves();
  if ($path === '/v1/admin/stock-in' && $method==='POST') return InventoryController::stockIn();
  if ($path === '/v1/admin/stock-adjust' && $method==='POST') return InventoryController::stockAdjust();
  if ($path === '/v1/admin/stock-summary' && $method==='GET') return InventoryController::stockSummary();
  if ($path === '/v1/admin/stock-consumption' && $method==='GET') return InventoryController::consumption();

  // ========== DISCOUNTS ==========
  if ($path === '/v1/cashier/discounts' && $method==='GET') return DiscountsController::cashierList();
  if ($path === '/v1/admin/discounts' && $method==='GET') return DiscountsController::list();
  if ($path === '/v1/admin/discounts' && $method==='POST') return DiscountsController::create();
  if (preg_match('#^/v1/admin/discounts/(\\d+)$#',$path,$m)) {
    if ($method==='PUT') return DiscountsController::update((int)$m[1]);
    if ($method==='DELETE') return DiscountsController::delete((int)$m[1]);
  }
  if ($path === '/v1/admin/discounts/history' && $method==='GET') return DiscountsController::history();

  // ========== PAYMENT METHODS ==========
  if ($path === '/v1/admin/payment-methods' && $method==='GET') return PaymentMethodsController::list();
  if ($path === '/v1/admin/payment-methods' && $method==='POST') return PaymentMethodsController::create();
  if (preg_match('#^/v1/admin/payment-methods/(\\d+)$#',$path,$m)) {
    if ($method==='PUT') return PaymentMethodsController::update((int)$m[1]);
    if ($method==='DELETE') return PaymentMethodsController::delete((int)$m[1]);
  }
  if (preg_match('#^/v1/admin/orders/(\\d+)/payments$#',$path,$m) && $method==='GET')
    return PaymentMethodsController::orderPayments((int)$m[1]);

  // ========== SHIFTS ==========
  if ($path === '/v1/admin/shifts' && $method==='GET') return ShiftsController::list();
  if ($path === '/v1/admin/shifts' && $method==='POST') return ShiftsController::create();
  if (preg_match('#^/v1/admin/shifts/(\\d+)/close$#',$path,$m) && $method==='PUT')
    return ShiftsController::close((int)$m[1]);
  if (preg_match('#^/v1/admin/shifts/(\\d+)/movements$#',$path,$m)) {
    if ($method==='GET') return ShiftsController::movements((int)$m[1]);
    if ($method==='POST') return ShiftsController::addMovement((int)$m[1]);
  }
  if (preg_match('#^/v1/admin/shifts/(\\d+)/summary$#',$path,$m) && $method==='GET')
    return ShiftsController::summary((int)$m[1]);

  // ========== REPORTS ==========
  if ($path === '/v1/admin/reports/revenue' && $method==='GET') return ReportsController::revenue();
  if ($path === '/v1/admin/reports/top-items' && $method==='GET') return ReportsController::topItems();
  if ($path === '/v1/admin/reports/inventory' && $method==='GET') return ReportsController::inventory();
  if ($path === '/v1/admin/reports/shifts' && $method==='GET') return ReportsController::shiftSummary();

  // ========== LOGS ==========
  if ($path === '/v1/admin/logs/audit' && $method==='GET') return LogsController::audit();
  if ($path === '/v1/admin/logs/activity' && $method==='GET') return LogsController::activity();

  // ========== TOOLS ==========
  if ($path === '/v1/admin/tools/export-menu' && $method==='GET') return ToolsController::exportMenu();
  if ($path === '/v1/admin/tools/import-menu' && $method==='POST') return ToolsController::importMenu();
  if ($path === '/v1/admin/tools/system-check' && $method==='GET') return ToolsController::systemCheck();

  // fallback 404
  http_response_code(404);
  echo json_encode(['ok'=>false,'error'=>'NOT_FOUND','message'=>'Endpoint not found','details'=>['path'=>$path]], JSON_UNESCAPED_UNICODE);

} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode(['ok'=>false,'error'=>'SERVER_ERROR','message'=>$e->getMessage()]);
}
