import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/fake_menu_repo.dart';
import '../../../data/repositories/menu_repo.dart';
import '../../../domain/models/menu_item.dart';

class MenuState {
  const MenuState({
    this.items = const <MenuItem>[],
    this.categories = const <String>[],
    this.query = '',
    this.selectedCategory,
    this.onlyActive = false,
    this.isLoading = false,
    this.errorMessage,
    this.hasLoadedInitial = false,
  });

  final List<MenuItem> items;
  final List<String> categories;
  final String query;
  final String? selectedCategory;
  final bool onlyActive;
  final bool isLoading;
  final String? errorMessage;
  final bool hasLoadedInitial;

  MenuState copyWith({
    List<MenuItem>? items,
    List<String>? categories,
    String? query,
    Object? selectedCategory = _unset,
    bool? onlyActive,
    bool? isLoading,
    Object? errorMessage = _unset,
    bool? hasLoadedInitial,
  }) {
    return MenuState(
      items: items ?? this.items,
      categories: categories ?? this.categories,
      query: query ?? this.query,
      selectedCategory:
          selectedCategory == _unset ? this.selectedCategory : selectedCategory as String?,
      onlyActive: onlyActive ?? this.onlyActive,
      isLoading: isLoading ?? this.isLoading,
      errorMessage:
          errorMessage == _unset ? this.errorMessage : errorMessage as String?,
      hasLoadedInitial: hasLoadedInitial ?? this.hasLoadedInitial,
    );
  }

  static const _unset = Object();
}

class MenuController extends StateNotifier<MenuState> {
  MenuController(this._repository) : super(const MenuState()) {
    _initialize();
  }

  final MenuRepository _repository;

  Future<void> _initialize() async {
    await loadMenu(refreshCategories: true);
  }

  Future<void> loadMenu({bool refreshCategories = false}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      List<String> categories = state.categories;
      if (!state.hasLoadedInitial || refreshCategories) {
        final allItems = await _repository.listMenu();
        categories = allItems
            .map((item) => item.category)
            .toSet()
            .toList()
          ..sort();
      }

      final filteredItems = await _repository.listMenu(
        query: state.query.isEmpty ? null : state.query,
        category: state.selectedCategory,
        isActive: state.onlyActive ? true : null,
      );

      state = state.copyWith(
        items: filteredItems,
        categories: categories,
        isLoading: false,
        errorMessage: null,
        hasLoadedInitial: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể tải menu: $error',
      );
    }
  }

  void setQuery(String query) {
    if (state.query == query) {
      return;
    }
    state = state.copyWith(query: query);
    loadMenu();
  }

  void setCategory(String? category) {
    if (state.selectedCategory == category) {
      return;
    }
    state = state.copyWith(selectedCategory: category);
    loadMenu();
  }

  void toggleOnlyActive(bool value) {
    if (state.onlyActive == value) {
      return;
    }
    state = state.copyWith(onlyActive: value);
    loadMenu();
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(errorMessage: null);
    }
  }
}

final menuControllerProvider =
    StateNotifierProvider<MenuController, MenuState>((ref) {
  final repository = ref.watch(menuRepositoryProvider);
  return MenuController(repository);
});
