import '../models/modifier.dart';
import '../models/modifier_group.dart';
import '../utils/json_utils.dart';
import 'api_service.dart';

/// Service encapsulating all topping/modifier related API calls.
class ModifierService {
  ModifierService._();

  static final ModifierService instance = ModifierService._();

  final ApiService _api = ApiService.instance;

  Future<List<ModifierGroup>> fetchGroups() async {
    final response = await _api.get('/admin/modifier-groups');
    if (response is List) {
      return response
          .whereType<Map<String, dynamic>>()
          .map(ModifierGroup.fromJson)
          .toList();
    }
    throw ApiException('Không lấy được danh sách nhóm topping');
  }

  Future<int> createGroup({
    required String name,
    int? minSelect,
    int? maxSelect,
    bool required = false,
    int? sort,
  }) async {
    final response = await _api.post('/admin/modifier-groups', {
      'name': name,
      if (minSelect != null) 'min_select': minSelect,
      if (maxSelect != null) 'max_select': maxSelect,
      'required': required ? 1 : 0,
      if (sort != null) 'sort': sort,
    });
    if (response is Map<String, dynamic>) {
      final id = parseInt(response['id']);
      if (id != null) return id;
    }
    throw ApiException('Không tạo được nhóm topping');
  }

  Future<void> updateGroup({
    required int id,
    required String name,
    int? minSelect,
    int? maxSelect,
    bool required = false,
    int? sort,
  }) async {
    await _api.put('/admin/modifier-groups/$id', {
      'name': name,
      if (minSelect != null) 'min_select': minSelect,
      if (maxSelect != null) 'max_select': maxSelect,
      'required': required ? 1 : 0,
      if (sort != null) 'sort': sort,
    });
  }

  Future<void> deleteGroup(int id) async {
    await _api.delete('/admin/modifier-groups/$id');
  }

  Future<List<Modifier>> fetchOptions(int groupId) async {
    final response = await _api.get('/admin/modifier-groups/$groupId/options');
    if (response is List) {
      return response
          .whereType<Map<String, dynamic>>()
          .map(Modifier.fromJson)
          .toList();
    }
    throw ApiException('Không lấy được danh sách topping trong nhóm');
  }

  Future<int> createOption({
    required int groupId,
    required String name,
    double? priceDelta,
    bool allowQuantity = false,
    int? maxQuantity,
    bool isDefault = false,
    int? sort,
  }) async {
    final response = await _api.post('/admin/modifier-groups/$groupId/options', {
      'name': name,
      if (priceDelta != null) 'price_delta': priceDelta,
      'allow_qty': allowQuantity ? 1 : 0,
      if (maxQuantity != null) 'max_qty': maxQuantity,
      'is_default': isDefault ? 1 : 0,
      if (sort != null) 'sort': sort,
    });
    if (response is Map<String, dynamic>) {
      final id = parseInt(response['id']);
      if (id != null) return id;
    }
    throw ApiException('Không tạo được topping mới');
  }

  Future<void> updateOption({
    required int optionId,
    required String name,
    double? priceDelta,
    bool allowQuantity = false,
    int? maxQuantity,
    bool isDefault = false,
    int? sort,
  }) async {
    await _api.put('/admin/modifier-options/$optionId', {
      'name': name,
      if (priceDelta != null) 'price_delta': priceDelta,
      'allow_qty': allowQuantity ? 1 : 0,
      if (maxQuantity != null) 'max_qty': maxQuantity,
      'is_default': isDefault ? 1 : 0,
      if (sort != null) 'sort': sort,
    });
  }

  Future<void> deleteOption(int optionId) async {
    await _api.delete('/admin/modifier-options/$optionId');
  }

  Future<List<int>> fetchItemGroupIds(int itemId) async {
    final response = await _api.get('/admin/items/$itemId/modifier-groups');
    if (response is List) {
      return response
          .map((entry) => entry is Map<String, dynamic>
              ? parseInt(entry['group_id'])
              : parseInt(entry))
          .whereType<int>()
          .toList();
    }
    throw ApiException('Không lấy được nhóm topping của món ăn');
  }

  Future<void> updateItemGroups({
    required int itemId,
    required List<int> groupIds,
  }) async {
    await _api.put('/admin/items/$itemId/modifier-groups', {
      'group_ids': groupIds,
    });
  }
}
