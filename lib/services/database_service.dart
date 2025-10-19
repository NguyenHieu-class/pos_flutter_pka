import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:mysql_client/mysql_client.dart';

import '../models/cart_item.dart';
import '../models/category.dart';
import '../models/menu_item.dart';

class DatabaseService {
  DatabaseService();

  MySQLConnection? _connection;
  bool _connected = false;

  final List<Category> _sampleCategories = <Category>[
    Category(id: 1, name: 'Khai vị'),
    Category(id: 2, name: 'Món chính'),
    Category(id: 3, name: 'Tráng miệng'),
  ];

  final List<MenuItem> _sampleMenuItems = <MenuItem>[
    MenuItem(
      id: 1,
      name: 'Gỏi cuốn tôm thịt',
      categoryId: 1,
      price: 55000,
      imagePath: '/data/restaurant/images/goi_cuon.jpg',
    ),
    MenuItem(
      id: 2,
      name: 'Salad bò rau mầm',
      categoryId: 1,
      price: 69000,
      imagePath: '/data/restaurant/images/salad_bo.jpg',
    ),
    MenuItem(
      id: 3,
      name: 'Bò lúc lắc',
      categoryId: 2,
      price: 129000,
      imagePath: '/data/restaurant/images/bo_luc_lac.jpg',
    ),
    MenuItem(
      id: 4,
      name: 'Cơm chiên hải sản',
      categoryId: 2,
      price: 99000,
      imagePath: '/data/restaurant/images/com_chien.jpg',
    ),
    MenuItem(
      id: 5,
      name: 'Bánh flan caramel',
      categoryId: 3,
      price: 39000,
      imagePath: '/data/restaurant/images/banh_flan.jpg',
    ),
    MenuItem(
      id: 6,
      name: 'Kem dừa non',
      categoryId: 3,
      price: 45000,
      imagePath: '/data/restaurant/images/kem_dua.jpg',
    ),
  ];

  final Map<int, Map<String, dynamic>> _offlineOrders = <int, Map<String, dynamic>>{};

  Future<void> init() async {
    if (_connected || _connection != null) {
      return;
    }
    try {
      final conn = await MySQLConnection.createConnection(
        host: '192.168.1.100',
        port: 3306,
        userName: 'pos_user',
        password: 'pos_pass',
        databaseName: 'restaurant_pos',
      );
      await conn.connect();
      _connection = conn;
      _connected = true;
      debugPrint('✅ Connected to MySQL successfully');
    } catch (error, stackTrace) {
      _connected = false;
      _connection = null;
      debugPrint('⚠️ Could not connect to MySQL: $error');
      debugPrint('$stackTrace');
    }
  }

  bool get isConnected => _connected && _connection != null;

  Future<List<Category>> fetchCategories() async {
    if (!isConnected) {
      return _sampleCategories;
    }

    final result = await _connection!.execute(
      'SELECT id, name FROM categories ORDER BY name ASC',
    );

    return result.rows
        .map((row) => Category.fromMap(row.assoc()))
        .toList(growable: false);
  }

  Future<List<MenuItem>> fetchMenuItems({int? categoryId, String? searchQuery}) async {
    if (!isConnected) {
      Iterable<MenuItem> items = _sampleMenuItems;
      if (categoryId != null) {
        items = items.where((item) => item.categoryId == categoryId);
      }
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final keyword = searchQuery.toLowerCase();
        items = items.where((item) => item.name.toLowerCase().contains(keyword));
      }
      return items.toList(growable: false);
    }

    final buffer = StringBuffer(
      'SELECT id, name, category_id, price, image_path FROM menu_items WHERE 1 = 1',
    );
    final params = <String, dynamic>{};

    if (categoryId != null) {
      buffer.write(' AND category_id = :categoryId');
      params['categoryId'] = categoryId;
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      buffer.write(' AND name LIKE :search');
      params['search'] = '%${searchQuery.trim()}%';
    }

    buffer.write(' ORDER BY name ASC');

    final result = await _connection!.execute(buffer.toString(), params);
    return result.rows
        .map((row) => MenuItem.fromMap(row.assoc()))
        .toList(growable: false);
  }

  Future<int> createOrder({
    required String tableNumber,
    required String orderType,
    required List<CartItem> items,
  }) async {
    if (items.isEmpty) {
      throw StateError('Không có món nào trong giỏ hàng');
    }

    if (!isConnected) {
      final orderId = DateTime.now().millisecondsSinceEpoch + Random().nextInt(999);
      _offlineOrders[orderId] = {
        'table_no': tableNumber,
        'type': orderType,
        'status': 'new',
        'items': items
            .map((item) => {
                  'item_id': item.menuItem.id,
                  'quantity': item.quantity,
                  'price': item.menuItem.price,
                  'note': item.note,
                })
            .toList(),
      };
      debugPrint('💾 Offline order stored locally (ID: $orderId).');
      return orderId;
    }

    final orderResult = await _connection!.execute(
      'INSERT INTO orders (table_no, type, status) VALUES (:tableNo, :type, :status)',
      <String, dynamic>{
        'tableNo': tableNumber,
        'type': orderType,
        'status': 'new',
      },
    );

    final orderId = orderResult.lastInsertID?.toInt() ?? 0;
    if (orderId <= 0) {
      throw StateError('Không thể lấy mã đơn hàng mới');
    }

    for (final item in items) {
      await _connection!.execute(
        'INSERT INTO order_items (order_id, item_id, quantity, price, note) '
        'VALUES (:orderId, :itemId, :quantity, :price, :note)',
        <String, dynamic>{
          'orderId': orderId,
          'itemId': item.menuItem.id,
          'quantity': item.quantity,
          'price': item.menuItem.price,
          'note': item.note,
        },
      );
    }

    return orderId;
  }

  Future<void> markOrderPaid(int orderId) async {
    if (!isConnected) {
      final order = _offlineOrders[orderId];
      if (order != null) {
        order['status'] = 'paid';
        debugPrint('💾 Offline order #$orderId marked as paid.');
        return;
      }
      throw StateError('Không tìm thấy đơn hàng offline: $orderId');
    }

    await _connection!.execute(
      'UPDATE orders SET status = :status WHERE id = :id',
      <String, dynamic>{'status': 'paid', 'id': orderId},
    );
  }

  Future<void> dispose() async {
    if (_connection != null) {
      await _connection!.close();
      _connection = null;
      _connected = false;
    }
  }
}
