import 'package:intl/intl.dart';

final NumberFormat _vndFormatter = NumberFormat.currency(
  locale: 'vi_VN',
  symbol: '₫',
  decimalDigits: 0,
);

String formatVND(num value) {
  return _vndFormatter.format(value);
}
