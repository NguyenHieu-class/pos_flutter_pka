class MenuItem {
  final String id;
  final String name;
  final String category;
  final double price;
  final bool isAvailable;

  const MenuItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.isAvailable = true,
  });

  MenuItem copyWith({
    String? id,
    String? name,
    String? category,
    double? price,
    bool? isAvailable,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}
