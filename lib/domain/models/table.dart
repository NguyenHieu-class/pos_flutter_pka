enum TableStatus { available, occupied, reserved }

extension TableStatusLabel on TableStatus {
  String get label => switch (this) {
        TableStatus.available => 'Available',
        TableStatus.occupied => 'Occupied',
        TableStatus.reserved => 'Reserved',
      };
}

class PosTable {
  final String id;
  final String name;
  final int capacity;
  final TableStatus status;

  const PosTable({
    required this.id,
    required this.name,
    required this.capacity,
    this.status = TableStatus.available,
  });

  PosTable copyWith({
    String? id,
    String? name,
    int? capacity,
    TableStatus? status,
  }) {
    return PosTable(
      id: id ?? this.id,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
    );
  }
}
