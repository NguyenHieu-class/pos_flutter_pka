/// Simple representation of a promotion/discount configuration.
class Promotion {
  const Promotion({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    this.code,
    this.startDate,
    this.endDate,
    this.minSubtotal,
    this.active = true,
  });

  static const _unset = Object();

  final int id;
  final String? code;
  final String name;
  final PromotionType type;
  final double value;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minSubtotal;
  final bool active;

  Promotion copyWith({
    int? id,
    Object? code = _unset,
    String? name,
    PromotionType? type,
    double? value,
    DateTime? startDate,
    DateTime? endDate,
    double? minSubtotal,
    bool? active,
  }) {
    return Promotion(
      id: id ?? this.id,
      code: code == _unset ? this.code : code as String?,
      name: name ?? this.name,
      type: type ?? this.type,
      value: value ?? this.value,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      minSubtotal: minSubtotal ?? this.minSubtotal,
      active: active ?? this.active,
    );
  }

  factory Promotion.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value.replaceFirst(' ', 'T'));
      }
      return null;
    }

    bool parseBool(dynamic value) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.toLowerCase();
        return normalized == '1' || normalized == 'true';
      }
      return false;
    }

    double? parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    int? parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is num) return value.toInt();
      return null;
    }

    return Promotion(
      id: parseInt(json['id']) ?? 0,
      code: json['code'] as String?,
      name: (json['name'] as String?) ?? '',
      type: PromotionTypeX.fromApi(json['type'] as String?),
      value: parseDouble(json['value']) ?? 0,
      minSubtotal: parseDouble(json['min_subtotal']),
      active: parseBool(json['active']),
      startDate: parseDate(json['starts_at']),
      endDate: parseDate(json['ends_at']),
    );
  }
}

/// Type of promotion: either a fixed amount or a percentage discount.
enum PromotionType { percentage, fixed }

extension PromotionTypeX on PromotionType {
  static PromotionType fromApi(String? value) {
    switch (value) {
      case 'amount':
        return PromotionType.fixed;
      case 'percent':
      default:
        return PromotionType.percentage;
    }
  }

  String get apiValue {
    switch (this) {
      case PromotionType.percentage:
        return 'percent';
      case PromotionType.fixed:
        return 'amount';
    }
  }

  String get label {
    switch (this) {
      case PromotionType.percentage:
        return 'Phần trăm';
      case PromotionType.fixed:
        return 'Trực tiếp';
    }
  }
}
