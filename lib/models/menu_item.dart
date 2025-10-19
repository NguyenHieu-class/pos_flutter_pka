class MenuItem {
  final int id;
  final String name;
  final int categoryId;
  final double price;
  final String imagePath;

  MenuItem({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.price,
    required this.imagePath,
  });

  factory MenuItem.fromMap(Map<String, dynamic> map) {
    final rawPrice = map['price'];
    return MenuItem(
      id: map['id'] is int ? map['id'] as int : int.parse(map['id'].toString()),
      name: map['name']?.toString() ?? '',
      categoryId: map['category_id'] is int
          ? map['category_id'] as int
          : int.parse(map['category_id'].toString()),
      price: rawPrice is double
          ? rawPrice
          : rawPrice is int
              ? rawPrice.toDouble()
              : double.tryParse(rawPrice.toString()) ?? 0,
      imagePath: map['image_path']?.toString() ?? '',
    );
  }
}
