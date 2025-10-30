import '../models/modifier.dart';
import 'api_service.dart';

/// Service dedicated to kitchen queue related operations.
class KitchenService {
  KitchenService._();

  static final KitchenService instance = KitchenService._();

  final ApiService _api = ApiService.instance;

  Future<List<KitchenTicket>> fetchKitchenQueue({KitchenFilter? filter}) async {
    final response = await _api.get(
      '/kitchen/queue',
      query: filter?.toQuery(),
    );
    if (response is List) {
      return response
          .map((item) => KitchenTicket.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw ApiException('Không tải được danh sách món trong bếp');
  }

  Future<List<KitchenTicket>> fetchKitchenHistory({KitchenFilter? filter}) async {
    final response = await _api.get(
      '/kitchen/history',
      query: filter?.toQuery(),
    );
    if (response is List) {
      return response
          .map((item) => KitchenTicket.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw ApiException('Không tải được lịch sử món bếp');
  }

  Future<void> updateItemStatus({
    required int orderItemId,
    required String status,
    String? reason,
  }) async {
    await _api.put('/kitchen/items/$orderItemId/status', {
      'kitchen_status': status,
      if (reason != null && reason.trim().isNotEmpty) 'cancel_reason': reason,
    });
  }
}

/// Representation of an item waiting in the kitchen queue.
class KitchenTicket {
  KitchenTicket({
    required this.orderItemId,
    required this.orderId,
    required this.itemName,
    required this.quantity,
    this.kitchenStatus,
    this.tableLabel,
    this.note,
    this.orderedAt,
    this.modifiers = const <Modifier>[],
    this.stationName,
    this.stationId,
    this.areaCode,
    this.areaName,
    this.tableCode,
    this.tableName,
    this.categoryId,
    this.categoryName,
    this.cancelReason,
    this.updatedAt,
  });

  factory KitchenTicket.fromJson(Map<String, dynamic> json) {
    final modifiersText = json['modifiers_text'] as String?;
    final modifiers = <Modifier>[];
    if (modifiersText != null && modifiersText.trim().isNotEmpty) {
      final parts = modifiersText.split(';');
      for (var i = 0; i < parts.length; i++) {
        final text = parts[i].trim();
        if (text.isEmpty) continue;
        modifiers.add(Modifier(
          id: i,
          name: text,
        ));
      }
    }

    final areaCode = json['area_code'] as String?;
    final tableCode = json['table_code'] as String?;
    final labelParts = <String>[];
    if (areaCode != null && areaCode.isNotEmpty) {
      labelParts.add('Khu $areaCode');
    }
    if (tableCode != null && tableCode.isNotEmpty) {
      labelParts.add('Bàn $tableCode');
    }

    return KitchenTicket(
      orderItemId: json['order_item_id'] as int? ?? json['id'] as int? ?? 0,
      orderId: json['order_id'] as int? ?? 0,
      itemName: json['item_name'] as String? ?? json['name'] as String? ?? '',
      quantity: json['qty'] as int? ?? json['quantity'] as int? ?? 0,
      kitchenStatus:
          json['kitchen_status'] as String? ?? json['status'] as String?,
      tableLabel: labelParts.isEmpty ? null : labelParts.join(' • '),
      note: json['note'] as String?,
      orderedAt: json['ordered_at'] as String? ?? json['created_at'] as String?,
      modifiers: modifiers,
      stationName: json['station_name'] as String?,
      stationId: json['station_id'] as int?,
      areaCode: areaCode,
      areaName: json['area_name'] as String?,
      tableCode: tableCode,
      tableName: json['table_name'] as String?,
      categoryId: json['category_id'] as int?,
      categoryName: json['category_name'] as String?,
      cancelReason: json['kitchen_cancel_reason'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  final int orderItemId;
  final int orderId;
  final String itemName;
  final int quantity;
  final String? kitchenStatus;
  final String? tableLabel;
  final String? note;
  final String? orderedAt;
  final List<Modifier> modifiers;
  final String? stationName;
  final int? stationId;
  final String? areaCode;
  final String? areaName;
  final String? tableCode;
  final String? tableName;
  final int? categoryId;
  final String? categoryName;
  final String? cancelReason;
  final String? updatedAt;
}

/// Filter helper for kitchen queue/history queries.
class KitchenFilter {
  KitchenFilter({
    this.areaCode,
    this.tableCode,
    this.stationId,
    this.categoryId,
    Set<String>? statuses,
  }) : statuses = statuses ?? <String>{};

  String? areaCode;
  String? tableCode;
  int? stationId;
  int? categoryId;
  final Set<String> statuses;

  Map<String, dynamic> toQuery() {
    final query = <String, dynamic>{};
    if (areaCode != null && areaCode!.isNotEmpty) {
      query['area_code'] = areaCode;
    }
    if (tableCode != null && tableCode!.isNotEmpty) {
      query['table_code'] = tableCode;
    }
    if (stationId != null) {
      query['station_id'] = stationId.toString();
    }
    if (categoryId != null) {
      query['category_id'] = categoryId.toString();
    }
    if (statuses.isNotEmpty) {
      query['statuses'] = statuses.join(',');
    }
    return query;
  }
}
