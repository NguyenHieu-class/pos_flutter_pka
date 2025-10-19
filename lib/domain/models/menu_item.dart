class MenuItem {
  final String id;
  final String name;
  final String category;
  final double price;
  final bool isActive;
  final String? imagePath;

  const MenuItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.isActive = true,
    this.imagePath,
  });

  MenuItem copyWith({
    String? id,
    String? name,
    String? category,
    double? price,
    bool? isActive,
    String? imagePath,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      isActive: isActive ?? this.isActive,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
