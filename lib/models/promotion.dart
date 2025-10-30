/// Simple representation of a promotion/discount configuration.
class Promotion {
  const Promotion({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    required this.startDate,
    required this.endDate,
    this.description,
    this.usageLimit,
    this.usageCount = 0,
    this.active = true,
  });

  final int id;
  final String name;
  final PromotionType type;
  final double value;
  final DateTime startDate;
  final DateTime endDate;
  final String? description;
  final int? usageLimit;
  final int usageCount;
  final bool active;

  Promotion copyWith({
    int? id,
    String? name,
    PromotionType? type,
    double? value,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
    int? usageLimit,
    int? usageCount,
    bool? active,
  }) {
    return Promotion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      value: value ?? this.value,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      description: description ?? this.description,
      usageLimit: usageLimit ?? this.usageLimit,
      usageCount: usageCount ?? this.usageCount,
      active: active ?? this.active,
    );
  }

}

/// Type of promotion: either a fixed amount or a percentage discount.
enum PromotionType { percentage, fixed }

extension PromotionTypeLabel on PromotionType {
  String get label {
    switch (this) {
      case PromotionType.percentage:
        return 'Phần trăm';
      case PromotionType.fixed:
        return 'Trực tiếp';
    }
  }
}
