import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/category.dart';
import '../services/database_service.dart';
import 'menu_controller.dart';

class CategoryController extends GetxController {
  final DatabaseService _databaseService = Get.find<DatabaseService>();

  final RxList<Category> categories = <Category>[].obs;
  final Rxn<Category> selectedCategory = Rxn<Category>();
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    ever<Category?>(selectedCategory, (category) {
      if (category != null) {
        Get.find<MenuController>().loadMenuItems(categoryId: category.id);
      }
    });
    loadCategories();
  }

  Future<void> loadCategories() async {
    try {
      isLoading.value = true;
      final data = await _databaseService.fetchCategories();
      categories.assignAll(data);
      if (data.isNotEmpty) {
        selectedCategory.value = data.first;
      }
    } catch (error, stackTrace) {
      debugPrint('Không thể tải danh mục: $error');
      debugPrint('$stackTrace');
    } finally {
      isLoading.value = false;
    }
  }

  void selectCategory(Category category) {
    selectedCategory.value = category;
  }
}
