import 'package:flutter/material.dart';

import '../models/area.dart';
import '../models/category.dart';
import '../models/item.dart';
import '../models/modifier.dart';
import '../models/order.dart';
import '../models/table.dart';
import 'api_service.dart';

/// Business logic helper for orders, categories, items and receipts.
class OrderService {
  OrderService._();

  static final OrderService instance = OrderService._();

  final ApiService _api = ApiService.instance;

  Future<List<Area>> fetchAreas() async {
    final response = await _api.get('/areas');
    if (response is List) {
      return response
          .map((item) => Area.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw ApiException('Không lấy được danh sách khu vực');
  }

  Future<int> createArea({required String name, String? code, int? sort, String? imagePath}) async {
    final response = await _api.post('/areas', {
      'name': name,
      if (code != null && code.isNotEmpty) 'code': code,
      if (sort != null) 'sort': sort,
      if (imagePath != null && imagePath.isNotEmpty) 'image_path': imagePath,
    });
    if (response is Map<String, dynamic>) {
      final id = response['id'];
      if (id is int) return id;
      if (id is String) {
        final parsed = int.tryParse(id);
        if (parsed != null) return parsed;
      }
    }
    throw ApiException('Không thể tạo khu vực');
  }

  Future<void> updateArea({
    required int id,
    required String name,
    String? code,
    int? sort,
    String? imagePath,
  }) async {
    await _api.put('/areas/$id', {
      'name': name,
      if (code != null) 'code': code.isEmpty ? null : code,
      if (sort != null) 'sort': sort,
      if (imagePath != null) 'image_path': imagePath.isEmpty ? null : imagePath,
    });
  }

  Future<void> deleteArea(int id) async {
    await _api.delete('/areas/$id');
  }

  Future<void> setAreaImage({
    required int areaId,
    required int mediaId,
    String? imagePath,
  }) async {
    await _api.post('/areas/$areaId/image', {
      'media_id': mediaId,
      if (imagePath != null && imagePath.isNotEmpty) 'image_path': imagePath,
    });
  }

  Future<List<DiningTable>> fetchTables({int? areaId, String? status}) async {
    final query = <String, String>{
      if (areaId != null) 'area_id': areaId.toString(),
      if (status != null) 'status': status,
    };
    final response = await _api.get('/tables', query: query.isEmpty ? null : query);
    if (response is List) {
      return response
          .map((item) => DiningTable.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw ApiException('Không lấy được danh sách bàn');
  }

  Future<int> createTable({
    required int areaId,
    required String name,
    String? code,
    int? number,
    int? capacity,
    String status = 'free',
  }) async {
    final response = await _api.post('/tables', {
      'area_id': areaId,
      'name': name,
      if (code != null && code.isNotEmpty) 'code': code,
      if (number != null) 'number': number,
      if (capacity != null) 'capacity': capacity,
      if (status.isNotEmpty) 'status': status,
    });
    if (response is Map<String, dynamic>) {
      final id = response['id'];
      if (id is int) return id;
      if (id is String) {
        final parsed = int.tryParse(id);
        if (parsed != null) return parsed;
      }
    }
    throw ApiException('Không thể tạo bàn mới');
  }

  Future<void> updateTable({
    required int id,
    required int areaId,
    required String name,
    String? code,
    int? number,
    int? capacity,
    String status = 'free',
  }) async {
    await _api.put('/tables/$id', {
      'area_id': areaId,
      'name': name,
      if (code != null) 'code': code.isEmpty ? null : code,
      if (number != null) 'number': number,
      if (capacity != null) 'capacity': capacity,
      if (status.isNotEmpty) 'status': status,
    });
  }

  Future<void> deleteTable(int id) async {
    await _api.delete('/tables/$id');
  }

  Future<Order> createOrder({required int tableId, String? customerName}) async {
    final response = await _api.post('/orders', {
      'table_id': tableId,
      if (customerName != null && customerName.isNotEmpty)
        'customer_name': customerName,
    });
    if (response is Map<String, dynamic>) {
      final orderId = response['order_id'] as int?;
      if (orderId == null) {
        throw ApiException('Không nhận được mã order mới');
      }
      return Order(
        id: orderId,
        tableId: tableId,
        tableName: response['table_name'] as String?,
        status: 'open',
        customerName: customerName,
      );
    }
    throw ApiException('Không thể tạo order mới');
  }

  Future<List<Category>> fetchCategories() async {
    final response = await _api.get('/categories');
    if (response is List) {
      return response
          .map((item) => Category.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw ApiException('Không lấy được danh mục');
  }

  Future<List<MenuItem>> fetchItems({
    int? categoryId,
    bool? enabled = true,
    String? keyword,
  }) async {
    final query = <String, String>{};
    if (categoryId != null) query['category_id'] = categoryId.toString();
    if (keyword != null && keyword.isNotEmpty) query['q'] = keyword;
    if (enabled == null) {
      query['enabled'] = 'all';
    } else {
      query['enabled'] = enabled ? '1' : '0';
    }
    final response = await _api.get('/items', query: query);
    if (response is List) {
      return response
          .map((item) => MenuItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw ApiException('Không lấy được món ăn');
  }

  Future<List<Modifier>> fetchItemModifiers(int itemId) async {
    final response = await _api.get('/items/$itemId/modifiers');
    if (response is List) {
      final modifiers = <Modifier>[];
      for (final group in response) {
        if (group is! Map<String, dynamic>) continue;
        final options = group['options'];
        if (options is! List) continue;
        for (final option in options) {
          if (option is Map<String, dynamic>) {
            modifiers.add(Modifier.fromJson({
              ...option,
              'group_id': group['group_id'],
              'group_name': group['name'],
            }));
          }
        }
      }
      return modifiers;
    }
    throw ApiException('Không lấy được topping');
  }

  Future<int> createCategory({required String name, int? sort}) async {
    final response = await _api.post('/categories', {
      'name': name,
      if (sort != null) 'sort': sort,
    });
    if (response is Map<String, dynamic>) {
      final id = response['id'];
      if (id is int) return id;
      if (id is String) {
        final parsed = int.tryParse(id);
        if (parsed != null) return parsed;
      }
    }
    throw ApiException('Không thể tạo danh mục');
  }

  Future<void> updateCategory({
    required int id,
    required String name,
    int? sort,
  }) async {
    await _api.put('/categories/$id', {
      'name': name,
      if (sort != null) 'sort': sort,
    });
  }

  Future<void> deleteCategory(int id) async {
    await _api.delete('/categories/$id');
  }

  Future<int> createItem({
    required String name,
    required double price,
    required int categoryId,
    String? description,
    String? sku,
    double? taxRate,
    bool enabled = true,
    int? stationId,
    String? imagePath,
  }) async {
    final response = await _api.post('/items', {
      'name': name,
      'price': price,
      'category_id': categoryId,
      if (description != null && description.isNotEmpty) 'description': description,
      if (sku != null && sku.isNotEmpty) 'sku': sku,
      'tax_rate': taxRate ?? 0,
      'enabled': enabled ? 1 : 0,
      if (stationId != null) 'station_id': stationId,
      if (imagePath != null && imagePath.isNotEmpty) 'image_path': imagePath,
    });
    if (response is Map<String, dynamic>) {
      final id = response['id'];
      if (id is int) return id;
      if (id is String) {
        final parsed = int.tryParse(id);
        if (parsed != null) return parsed;
      }
    }
    throw ApiException('Không thể tạo món ăn');
  }

  Future<void> updateItem({
    required int id,
    required String name,
    required double price,
    required int categoryId,
    String? description,
    String? sku,
    double? taxRate,
    bool enabled = true,
    int? stationId,
    String? imagePath,
  }) async {
    await _api.put('/items/$id', {
      'name': name,
      'price': price,
      'category_id': categoryId,
      if (description != null)
        'description': description.isEmpty ? null : description,
      if (sku != null) 'sku': sku.isEmpty ? null : sku,
      'tax_rate': taxRate ?? 0,
      'enabled': enabled ? 1 : 0,
      if (stationId != null) 'station_id': stationId,
      if (imagePath != null) 'image_path': imagePath.isEmpty ? null : imagePath,
    });
  }

  Future<void> deleteItem(int id) async {
    await _api.delete('/items/$id');
  }

  Future<MenuItem> fetchItemDetail(int id) async {
    final response = await _api.get('/items/$id');
    if (response is Map<String, dynamic>) {
      return MenuItem.fromJson(response);
    }
    throw ApiException('Không lấy được chi tiết món ăn');
  }

  Future<Order> fetchOrderDetail(int orderId) async {
    final response = await _api.get('/orders/$orderId');
    if (response is Map<String, dynamic>) {
      return Order.fromJson(response);
    }
    throw ApiException('Không lấy được chi tiết order');
  }

  Future<void> addItemToOrder({
    required int orderId,
    required int itemId,
    required int quantity,
    List<int>? modifiers,
    String? note,
  }) async {
    await _api.post('/orders/$orderId/items', {
      'item_id': itemId,
      'qty': quantity,
      if (modifiers != null && modifiers.isNotEmpty) 'modifiers': modifiers,
      if (note != null && note.isNotEmpty) 'note': note,
    });
  }

  Future<Map<String, dynamic>> checkoutOrder(int orderId) async {
    final response = await _api.post('/orders/$orderId/checkout', {});
    if (response is Map<String, dynamic>) {
      return response['receipt'] as Map<String, dynamic>? ?? response;
    }
    throw ApiException('Không thể thanh toán hóa đơn');
  }

  Future<List<Map<String, dynamic>>> fetchReceipts({
    required String from,
    required String to,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _api.get('/admin/receipts', query: {
      'from': from,
      'to': to,
      'page': page.toString(),
      'page_size': pageSize.toString(),
    });
    if (response is Map<String, dynamic>) {
      final rows = response['rows'];
      if (rows is List) {
        return rows.cast<Map<String, dynamic>>();
      }
    } else if (response is List) {
      return response.cast<Map<String, dynamic>>();
    }
    throw ApiException('Không lấy được hóa đơn đã thanh toán');
  }

  Future<Map<String, dynamic>> fetchReceiptDetail(int receiptId) async {
    final response = await _api.get('/admin/receipts/$receiptId');
    if (response is Map<String, dynamic>) {
      return response;
    }
    throw ApiException('Không lấy được chi tiết hóa đơn');
  }

  Future<Map<String, dynamic>> uploadItemImage(List<int> bytes, String filename) async {
    final response = await _api.uploadFile(
      '/uploads/items',
      fieldName: 'file',
      bytes: bytes,
      filename: filename,
    );
    if (response is Map<String, dynamic>) {
      return response;
    }
    throw ApiException('Không thể tải ảnh món ăn');
  }

  Future<Map<String, dynamic>> uploadAreaImage(List<int> bytes, String filename) async {
    final response = await _api.uploadFile(
      '/uploads/areas',
      fieldName: 'file',
      bytes: bytes,
      filename: filename,
    );
    if (response is Map<String, dynamic>) {
      return response;
    }
    throw ApiException('Không thể tải ảnh khu vực');
  }

  Future<void> setItemImage({required int itemId, required int mediaId, String? imagePath}) async {
    await _api.post('/items/$itemId/image', {
      'media_id': mediaId,
      if (imagePath != null && imagePath.isNotEmpty) 'image_path': imagePath,
    });
  }
}
