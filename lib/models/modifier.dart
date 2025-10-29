/// Model describing an optional modifier/topping for a menu item.
class Modifier {
  Modifier({
    required this.id,
    required this.name,
    this.price,
  });

  factory Modifier.fromJson(Map<String, dynamic> json) {
    return Modifier(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble(),
    );
  }

  final int id;
  final String name;
  final double? price;
}
