class Category {
  final int id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] is int ? map['id'] as int : int.parse(map['id'].toString()),
      name: map['name']?.toString() ?? '',
    );
  }
}
