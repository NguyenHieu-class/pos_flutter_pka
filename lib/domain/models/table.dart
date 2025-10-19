class PosTable {
  final String id;
  final String name;
  final int capacity;
  final bool isOccupied;

  const PosTable({
    required this.id,
    required this.name,
    required this.capacity,
    this.isOccupied = false,
  });

  PosTable copyWith({
    String? id,
    String? name,
    int? capacity,
    bool? isOccupied,
  }) {
    return PosTable(
      id: id ?? this.id,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      isOccupied: isOccupied ?? this.isOccupied,
    );
  }
}
