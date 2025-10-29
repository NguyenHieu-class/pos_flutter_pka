/// Category model used to group menu items for browsing.
class Category {
  Category({
    required this.id,
    required this.name,
    this.imageUrl,
    this.description,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      description: json['description'] as String?,
    );
  }

  final int id;
  final String name;
  final String? imageUrl;
  final String? description;
}
