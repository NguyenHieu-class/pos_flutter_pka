/// Dining table model used for table selection in the cashier flow.
class DiningTable {
  DiningTable({
    required this.id,
    required this.name,
    this.areaId,
    this.status,
    this.capacity,
  });

  factory DiningTable.fromJson(Map<String, dynamic> json) {
    return DiningTable(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      areaId: json['area_id'] as int?,
      status: json['status'] as String?,
      capacity: json['capacity'] as int?,
    );
  }

  final int id;
  final String name;
  final int? areaId;
  final String? status;
  final int? capacity;
}
