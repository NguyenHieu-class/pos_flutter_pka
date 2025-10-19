class OrderItem {
  final String id;
  final String itemId;
  final String name;
  final double unitPrice;
  final int quantity;
  final String? note;

  const OrderItem({
    required this.id,
    required this.itemId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    this.note,
  });

  double get total => unitPrice * quantity;

  OrderItem copyWith({
    String? id,
    String? itemId,
    String? name,
    double? unitPrice,
    int? quantity,
    Object? note = _unset,
  }) {
    return OrderItem(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      name: name ?? this.name,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      note: note == _unset ? this.note : note as String?,
    );
  }

  static const _unset = Object();
}
