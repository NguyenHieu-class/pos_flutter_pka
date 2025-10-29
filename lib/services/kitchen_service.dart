import '../models/modifier.dart';
import 'api_service.dart';

/// Service dedicated to kitchen queue related operations.
class KitchenService {
  KitchenService._();

  static final KitchenService instance = KitchenService._();

  final ApiService _api = ApiService.instance;

  Future<List<KitchenTicket>> fetchKitchenQueue() async {
    final response = await _api.get('/kitchen/queue');
    if (response is List) {
      return response
          .map((item) => KitchenTicket.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw ApiException('Không tải được danh sách món trong bếp');
  }

  Future<void> updateItemStatus({
    required int orderItemId,
    required String status,
  }) async {
    await _api.put('/kitchen/items/$orderItemId/status', {'status': status});
  }
}

/// Representation of an item waiting in the kitchen queue.
class KitchenTicket {
  KitchenTicket({
    required this.orderItemId,
    required this.itemName,
    required this.quantity,
    this.status,
    this.tableName,
    this.note,
    this.orderedAt,
    this.modifiers = const <Modifier>[],
  });

  factory KitchenTicket.fromJson(Map<String, dynamic> json) {
    final modifiers = json['modifiers'];
    return KitchenTicket(
      orderItemId: json['order_item_id'] as int? ?? json['id'] as int? ?? 0,
      itemName: json['item_name'] as String? ?? json['name'] as String? ?? '',
      quantity: json['qty'] as int? ?? json['quantity'] as int? ?? 0,
      status: json['status'] as String?,
      tableName: json['table_name'] as String?,
      note: json['note'] as String?,
      orderedAt: json['ordered_at'] as String? ?? json['created_at'] as String?,
      modifiers: modifiers is List
          ? modifiers
              .map((m) => Modifier.fromJson(m as Map<String, dynamic>))
              .toList()
          : const <Modifier>[],
    );
  }

  final int orderItemId;
  final String itemName;
  final int quantity;
  final String? status;
  final String? tableName;
  final String? note;
  final String? orderedAt;
  final List<Modifier> modifiers;
}
