import '../utils/json_utils.dart';

/// Model describing an optional modifier/topping for a menu item.
class Modifier {
  Modifier({
    required this.id,
    required this.name,
    this.price,
    this.groupId,
    this.groupName,
    this.quantity,
    this.allowQuantity = false,
    this.maxQuantity,
    this.isDefault = false,
    this.sort,
  });

  factory Modifier.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['option_id'] ?? json['modifier_id'];
    final parsedId = rawId is int
        ? rawId
        : int.tryParse(rawId?.toString() ?? '') ?? 0;
    final priceValue = json['price'] ?? json['price_delta'] ?? json['unit_delta'];
    final groupIdValue = parseInt(json['group_id']);
    final quantityValue = parseInt(json['qty']) ?? parseInt(json['quantity']);
    final allowQtyRaw = json['allow_qty'] ?? json['allow_quantity'];
    final maxQtyValue = parseInt(json['max_qty']);
    final isDefaultRaw = json['is_default'];
    final sortValue =
        parseInt(json['sort']) ?? parseInt(json['option_sort']) ?? parseInt(json['position']);
    final parsedPrice = priceValue is num
        ? priceValue.toDouble()
        : parseDouble(priceValue);
    return Modifier(
      id: parsedId,
      name: (json['name'] as String?) ??
          (json['option_name'] as String?) ??
          (json['modifier_name'] as String?) ??
          '',
      price: parsedPrice,
      groupId: groupIdValue,
      groupName: json['group_name'] as String?,
      quantity: quantityValue,
      allowQuantity: _truthy(allowQtyRaw),
      maxQuantity: maxQtyValue,
      isDefault: _truthy(isDefaultRaw),
      sort: sortValue,
    );
  }

  final int id;
  final String name;
  final double? price;
  final int? groupId;
  final String? groupName;
  final int? quantity;
  final bool allowQuantity;
  final int? maxQuantity;
  final bool isDefault;
  final int? sort;
}

bool _truthy(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == '1' || normalized == 'true' || normalized == 'yes';
  }
  return false;
}
