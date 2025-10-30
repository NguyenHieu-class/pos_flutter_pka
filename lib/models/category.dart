/// Category model used to group menu items for browsing.
class Category {
  Category({
    required this.id,
    required this.name,
    this.imageUrl,
    this.description,
    this.sort = 0,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      description: json['description'] as String?,
      sort: json['sort'] is int
          ? json['sort'] as int
          : int.tryParse('${json['sort'] ?? 0}') ?? 0,
    );
  }

  final int id;
  final String name;
  final String? imageUrl;
  final String? description;
  final int sort;
}
