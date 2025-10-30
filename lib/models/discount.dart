import '../utils/json_utils.dart';

/// Represents a discount/promotion that can be applied during checkout.
class Discount {
  const Discount({
    required this.id,
    this.code,
    required this.name,
    required this.type,
    required this.value,
    required this.minSubtotal,
    this.startsAt,
    this.endsAt,
  });

  factory Discount.fromJson(Map<String, dynamic> json) {
    final typeString = (json['type'] as String?)?.toLowerCase();
    return Discount(
      id: parseInt(json['id']) ?? 0,
      code: (json['code'] as String?)?.isEmpty ?? true
          ? null
          : json['code'] as String?,
      name: json['name'] as String? ?? '',
      type: DiscountTypeX.fromJson(typeString),
      value: parseDouble(json['value']) ?? 0,
      minSubtotal: parseDouble(json['min_subtotal']) ?? 0,
      startsAt: _parseDate(json['starts_at']),
      endsAt: _parseDate(json['ends_at']),
    );
  }

  final int id;
  final String? code;
  final String name;
  final DiscountType type;
  final double value;
  final double minSubtotal;
  final DateTime? startsAt;
  final DateTime? endsAt;

  /// Calculates the monetary amount deducted when applied to [subtotal].
  double calculateAmount(double subtotal) {
    if (subtotal <= 0) return 0;
    double amount;
    switch (type) {
      case DiscountType.percent:
        amount = subtotal * (value / 100);
        break;
      case DiscountType.amount:
        amount = value;
        break;
    }
    if (amount < 0) return 0;
    if (amount > subtotal) return subtotal;
    return amount;
  }

  /// Returns a human readable short label combining code & name.
  String get label {
    if (code != null && code!.isNotEmpty) {
      return '$code - $name';
    }
    return name;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

/// Types of discounts supported by the system.
enum DiscountType { percent, amount }

extension DiscountTypeX on DiscountType {
  static DiscountType fromJson(String? value) {
    switch (value) {
      case 'percent':
        return DiscountType.percent;
      case 'amount':
        return DiscountType.amount;
      default:
        return DiscountType.amount;
    }
  }

  String get label {
    switch (this) {
      case DiscountType.percent:
        return 'Phần trăm';
      case DiscountType.amount:
        return 'Số tiền';
    }
  }
}
