import 'package:intl/intl.dart';

import '../models/promotion.dart';
import 'api_service.dart';

/// Service layer for managing promotions/discounts from the admin panel.
class PromotionService {
  PromotionService._();

  static final PromotionService instance = PromotionService._();

  final ApiService _api = ApiService.instance;
  final DateFormat _apiDateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  Future<List<Promotion>> fetchPromotions() async {
    final response = await _api.get('/admin/discounts');
    if (response is List) {
      return response
          .whereType<Map<String, dynamic>>()
          .map(Promotion.fromJson)
          .toList();
    }
    throw ApiException('Không lấy được danh sách khuyến mãi');
  }

  Future<Promotion> createPromotion({
    required String name,
    required PromotionType type,
    required double value,
    String? code,
    double? minSubtotal,
    DateTime? startDate,
    DateTime? endDate,
    bool active = true,
  }) async {
    final payload = _encodePayload(
      name: name,
      type: type,
      value: value,
      code: code,
      minSubtotal: minSubtotal,
      startDate: startDate,
      endDate: endDate,
      active: active,
    );
    final response = await _api.post('/admin/discounts', payload);
    if (response is Map<String, dynamic>) {
      return Promotion.fromJson(response);
    }
    throw ApiException('Không tạo được khuyến mãi');
  }

  Future<Promotion> updatePromotion({
    required int id,
    required String name,
    required PromotionType type,
    required double value,
    String? code,
    double? minSubtotal,
    DateTime? startDate,
    DateTime? endDate,
    bool active = true,
  }) async {
    final payload = _encodePayload(
      name: name,
      type: type,
      value: value,
      code: code,
      minSubtotal: minSubtotal,
      startDate: startDate,
      endDate: endDate,
      active: active,
    );
    final response = await _api.put('/admin/discounts/$id', payload);
    if (response is Map<String, dynamic>) {
      return Promotion.fromJson(response);
    }
    throw ApiException('Không cập nhật được khuyến mãi');
  }

  Future<void> deletePromotion(int id) async {
    await _api.delete('/admin/discounts/$id');
  }

  Map<String, dynamic> _encodePayload({
    required String name,
    required PromotionType type,
    required double value,
    String? code,
    double? minSubtotal,
    DateTime? startDate,
    DateTime? endDate,
    required bool active,
  }) {
    final payload = <String, dynamic>{
      'name': name,
      'type': type.apiValue,
      'value': value,
      'active': active ? 1 : 0,
      'min_subtotal': minSubtotal ?? 0,
    };
    final trimmedCode = code?.trim();
    if (trimmedCode != null && trimmedCode.isNotEmpty) {
      payload['code'] = trimmedCode.toUpperCase();
    } else {
      payload['code'] = null;
    }
    payload['starts_at'] = startDate != null ? _formatDate(startDate) : null;
    payload['ends_at'] = endDate != null ? _formatDate(endDate) : null;
    return payload;
  }

  String _formatDate(DateTime value) {
    return _apiDateFormat.format(value);
  }
}
