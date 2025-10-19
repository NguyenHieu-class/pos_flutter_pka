import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/menu_repo.dart';
import '../../../domain/models/menu_item.dart';
import 'menu_controller.dart';

class MenuAdminState {
  const MenuAdminState({
    this.items = const <MenuItem>[],
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final List<MenuItem> items;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;

  MenuAdminState copyWith({
    List<MenuItem>? items,
    bool? isLoading,
    bool? isSubmitting,
    Object? errorMessage = _unset,
  }) {
    return MenuAdminState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage:
          errorMessage == _unset ? this.errorMessage : errorMessage as String?,
    );
  }

  static const _unset = Object();
}

class MenuAdminController extends StateNotifier<MenuAdminState> {
  MenuAdminController(this._ref, this._repository)
      : super(const MenuAdminState()) {
    loadItems();
  }

  final Ref _ref;
  final MenuRepository _repository;

  Future<void> loadItems() async {
    try {
      await _refreshItems(showLoading: true);
    } catch (_) {
      // Error state handled via state updates.
    }
  }

  Future<bool> createItem({
    required String name,
    required String category,
    required double price,
    required bool isActive,
    String? imagePath,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final id = _generateId(name);
      final item = MenuItem(
        id: id,
        name: name,
        category: category,
        price: price,
        isActive: isActive,
        imagePath: imagePath,
      );
      await _repository.create(item);
      await _refreshItems();
      state = state.copyWith(isSubmitting: false);
      _ref.invalidate(menuControllerProvider);
      return true;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Không thể thêm món: $error',
      );
      return false;
    }
  }

  Future<bool> updateItem(MenuItem item) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      await _repository.update(item);
      await _refreshItems();
      state = state.copyWith(isSubmitting: false);
      _ref.invalidate(menuControllerProvider);
      return true;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Không thể cập nhật món: $error',
      );
      return false;
    }
  }

  Future<bool> toggleItem(String itemId, bool isActive) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      await _repository.toggleActive(itemId, isActive);
      await _refreshItems();
      state = state.copyWith(isSubmitting: false);
      _ref.invalidate(menuControllerProvider);
      return true;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Không thể cập nhật trạng thái: $error',
      );
      return false;
    }
  }

  Future<void> _refreshItems({bool showLoading = false}) async {
    if (showLoading) {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }
    try {
      final items = await _repository.listMenu();
      state = state.copyWith(
        items: items,
        isLoading: false,
        errorMessage: null,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể tải danh sách món: $error',
      );
      rethrow;
    }
  }

  String _generateId(String name) {
    final normalized = name
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
        .toUpperCase();
    final prefixLength = normalized.isEmpty
        ? 4
        : normalized.length > 4
            ? 4
            : normalized.length;
    final prefix = normalized.isEmpty
        ? 'ITEM'
        : normalized.substring(0, prefixLength);
    final suffix = DateTime.now()
        .millisecondsSinceEpoch
        .toRadixString(36)
        .toUpperCase();
    return '$prefix$suffix';
  }
}

final menuAdminControllerProvider =
    StateNotifierProvider<MenuAdminController, MenuAdminState>((ref) {
  final repository = ref.watch(menuRepositoryProvider);
  return MenuAdminController(ref, repository);
});
