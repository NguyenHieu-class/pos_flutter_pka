/// Dining table model used for table selection in the cashier flow.
class DiningTable {
  DiningTable({
    required this.id,
    required this.name,
    this.areaId,
    this.areaName,
    this.status,
    this.capacity,
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
      areaId: json['area_id'] as int?,
      areaName: json['area_name'] as String?,
      status: json['status'] as String? ?? json['table_status'] as String?,
      capacity: json['capacity'] as int?,
    );
  }

  final int id;
  final String name;
  final int? areaId;
  final String? areaName;
  final String? status;
  final int? capacity;
}
