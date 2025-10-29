/// Model describing an optional modifier/topping for a menu item.
class Modifier {
  Modifier({
    required this.id,
    required this.name,
    this.price,
    this.groupId,
    this.groupName,
    this.quantity,
  });

  factory Modifier.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['option_id'] ?? json['modifier_id'];
    final parsedId = rawId is int
        ? rawId
        : int.tryParse(rawId?.toString() ?? '') ?? 0;
    final priceValue =
        json['price'] ?? json['price_delta'] ?? json['unit_delta'];
    return Modifier(
      id: parsedId,
      name: (json['name'] as String?) ??
          (json['option_name'] as String?) ??
          (json['modifier_name'] as String?) ??
          '',
      price: priceValue is num ? priceValue.toDouble() : null,
      groupId: json['group_id'] as int?,
      groupName: json['group_name'] as String?,
      quantity: json['qty'] as int? ?? json['quantity'] as int?,
    );
  }

  final int id;
  final String name;
  final double? price;
  final int? groupId;
  final String? groupName;
  final int? quantity;
}
