/// Utility helpers for parsing loosely typed JSON values coming from the API.
///
/// The backend frequently returns numeric values as strings which causes
/// runtime type cast exceptions when the app expects numbers. These helpers
/// safely convert those values while keeping null-safety intact.
double? parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}

int? parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}
