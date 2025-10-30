/// Dining area model for grouping tables.
class Area {
  Area({
    required this.id,
    required this.name,
    this.code,
    this.sort,
    this.imageUrl,
  });

  factory Area.fromJson(Map<String, dynamic> json) {
    final sortValue = json['sort'];
    return Area(
      id: json['id'] as int? ?? 0,
      name: json['name']?.toString().trim().isNotEmpty == true
          ? json['name'].toString()
          : 'Khu ${json['id'] ?? ''}',
      code: json['code']?.toString(),
      sort: sortValue is int
          ? sortValue
          : int.tryParse(sortValue?.toString() ?? ''),
      imageUrl: json['image_url'] as String?,
    );
  }

  final int id;
  final String name;
  final String? code;
  final int? sort;
  final String? imageUrl;

  String get displayLabel => name.isNotEmpty
      ? name
      : (code != null && code!.isNotEmpty ? code! : 'Khu $id');
}

