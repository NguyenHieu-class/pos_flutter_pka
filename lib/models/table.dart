/// Dining table model used for table selection in the cashier flow.
class DiningTable {
  DiningTable({
    required this.id,
    required this.name,
    this.code,
    this.number,
    this.areaId,
    this.areaName,
    this.status,
    this.capacity,
    this.imageUrl,
    this.openOrderId,
  });

  factory DiningTable.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String?;
    final code = json['code']?.toString();
    final number = json['number']?.toString();
    final fallbackName = number != null
        ? 'Bàn $number'
        : 'Bàn ${json['id'] ?? ''}';
    return DiningTable(
      id: json['id'] as int? ?? 0,
      name: name ?? code ?? fallbackName,
      code: code,
      number: int.tryParse(number ?? ''),
      areaId: json['area_id'] as int?,
      areaName: json['area_name'] as String?,
      status: json['status'] as String? ?? json['table_status'] as String?,
      capacity: json['capacity'] as int?,
      imageUrl: json['image_url'] as String?,
      openOrderId: json['open_order_id'] is int
          ? json['open_order_id'] as int
          : int.tryParse(json['open_order_id']?.toString() ?? ''),
    );
  }

  final int id;
  final String name;
  final String? code;
  final int? number;
  final int? areaId;
  final String? areaName;
  final String? status;
  final int? capacity;
  final String? imageUrl;
  final int? openOrderId;
}
