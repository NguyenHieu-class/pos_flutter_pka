import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/menu_item.dart';
import '../services/database_service.dart';

class MenuController extends GetxController {
  final DatabaseService _databaseService = Get.find<DatabaseService>();

  final RxList<MenuItem> menuItems = <MenuItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  int? _currentCategoryId;

  Future<void> loadMenuItems({int? categoryId, String? query}) async {
    try {
      isLoading.value = true;
      _currentCategoryId = categoryId ?? _currentCategoryId;
      final keyword = query ?? searchQuery.value;
      final data = await _databaseService.fetchMenuItems(
        categoryId: _currentCategoryId,
        searchQuery: keyword,
      );
      menuItems.assignAll(data);
    } catch (error, stackTrace) {
      debugPrint('Không thể tải món ăn: $error');
      debugPrint('$stackTrace');
    } finally {
      isLoading.value = false;
    }
  }

  void setSearchQuery(String value) {
    searchQuery.value = value;
    loadMenuItems(query: value);
  }
}
