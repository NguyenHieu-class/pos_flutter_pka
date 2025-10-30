import '../utils/json_utils.dart';
import 'modifier.dart';

/// Menu item model describing dishes and beverages.
class MenuItem {
  MenuItem({
    required this.id,
    required this.name,
    required this.price,
    this.categoryId,
    this.description,
    this.imageUrl,
    this.sku,
    this.stationId,
    this.taxRate = 0,
    this.enabled = true,
    this.categoryName,
    this.stationName,
    this.modifiers = const <Modifier>[],
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    final modifiersJson = json['modifiers'];
    return MenuItem(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      price: parseDouble(json['price']) ?? 0,
      categoryId: json['category_id'] as int?,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      sku: json['sku'] as String?,
      stationId: json['station_id'] as int?,
      taxRate: parseDouble(json['tax_rate']) ?? 0,
      enabled: json['enabled'] is bool
          ? json['enabled'] as bool
          : '${json['enabled'] ?? 1}' != '0',
      categoryName: json['category_name'] as String?,
      stationName: json['station_name'] as String?,
      modifiers: modifiersJson is List
          ? modifiersJson
              .map((m) => Modifier.fromJson(m as Map<String, dynamic>))
              .toList()
          : const <Modifier>[],
    );
  }

  final int id;
  final String name;
  final double price;
  final int? categoryId;
  final String? description;
  final String? imageUrl;
  final String? sku;
  final int? stationId;
  final double taxRate;
  final bool enabled;
  final String? categoryName;
  final String? stationName;
  final List<Modifier> modifiers;
}
