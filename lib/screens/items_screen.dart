import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/category.dart';
import '../models/item.dart';
import '../models/modifier_group.dart';
import '../services/api_service.dart';
import '../services/order_service.dart';
import '../services/modifier_service.dart';

/// Screen displaying menu items and allowing filtering by category.
class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  final _orderService = OrderService.instance;
  final _modifierService = ModifierService.instance;
  late Future<List<MenuItem>> _itemsFuture;
  List<Category> _categories = const [];
  Category? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = 'active';

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadInitial() {
    _itemsFuture = _orderService.fetchItems();
    _orderService.fetchCategories().then((value) {
      setState(() {
        _categories = value;
      });
    });
  }

  Future<void> _onCategorySelected(Category? category) async {
    setState(() {
      _selectedCategory = category;
      _loadItems();
    });
  }

  void _loadItems() {
    final keyword = _searchController.text.trim();
    final enabled = _statusFilter == 'all'
        ? null
        : _statusFilter == 'active'
            ? true
            : false;
    setState(() {
      _itemsFuture = _orderService.fetchItems(
        categoryId: _selectedCategory?.id,
        enabled: enabled,
        keyword: keyword.isEmpty ? null : keyword,
      );
    });
  }

  String _categoryLabelFor(MenuItem item) {
    if (item.categoryName != null && item.categoryName!.isNotEmpty) {
      return item.categoryName!;
    }
    final match = _categories.firstWhere(
      (category) => category.id == item.categoryId,
      orElse: () => Category(id: item.categoryId ?? 0, name: 'Không rõ'),
    );
    return match.name;
  }

  Future<void> _showItemDialog({MenuItem? item}) async {
    if (_categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng tạo danh mục trước')),
      );
      return;
    }
    final nameController = TextEditingController(text: item?.name ?? '');
    final priceController = TextEditingController(
      text: item != null ? item.price.toStringAsFixed(0) : '',
    );
    final descriptionController =
        TextEditingController(text: item?.description ?? '');
    final skuController = TextEditingController(text: item?.sku ?? '');
    final formKey = GlobalKey<FormState>();
    final messenger = ScaffoldMessenger.of(context);
    int? selectedCategoryId = item?.categoryId ?? _categories.first.id;
    bool enabled = item?.enabled ?? true;
    final picker = ImagePicker();
    XFile? selectedImage;
    Uint8List? previewBytes;
    String? previewUrl = item?.imageUrl;

    final shouldReload = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(item == null
                  ? 'Thêm món mới'
                  : 'Chỉnh sửa món ăn'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 96,
                              height: 96,
                              child: previewBytes != null
                                  ? Image.memory(previewBytes!, fit: BoxFit.cover)
                                  : previewUrl != null
                                      ? Image.network(previewUrl!, fit: BoxFit.cover)
                                      : Container(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .surfaceVariant,
                                          child: const Icon(Icons.image, size: 40),
                                        ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextButton.icon(
                                  onPressed: isSubmitting
                                      ? null
                                      : () async {
                                          try {
                                            final file = await picker.pickImage(
                                              source: ImageSource.gallery,
                                              imageQuality: 85,
                                            );
                                            if (file == null) return;
                                            final bytes = await file.readAsBytes();
                                            setStateDialog(() {
                                              selectedImage = file;
                                              previewBytes = bytes;
                                              previewUrl = null;
                                            });
                                          } catch (error) {
                                            messenger.showSnackBar(
                                              SnackBar(content: Text('Không thể chọn ảnh: $error')),
                                            );
                                          }
                                        },
                                  icon: const Icon(Icons.photo_library_outlined),
                                  label: Text(previewBytes == null && previewUrl == null
                                      ? 'Chọn ảnh đại diện'
                                      : 'Đổi ảnh'),
                                ),
                                if (previewBytes != null || previewUrl != null)
                                  Text(
                                    'Ảnh sẽ hiển thị trong danh sách món ăn',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        value: selectedCategoryId,
                        items: _categories
                            .map(
                              (category) => DropdownMenuItem<int>(
                                value: category.id,
                                child: Text(category.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setStateDialog(() {
                            selectedCategoryId = value;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Danh mục',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Tên món',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập tên món';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: priceController,
                        decoration: const InputDecoration(
                          labelText: 'Giá bán',
                          suffixText: '₫',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập giá';
                          }
                          final normalized = value.trim().replaceAll(',', '.');
                          if (double.tryParse(normalized) == null) {
                            return 'Giá không hợp lệ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: skuController,
                        decoration: const InputDecoration(
                          labelText: 'Mã SKU (tùy chọn)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Mô tả',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: enabled,
                        onChanged: (value) {
                          setStateDialog(() {
                            enabled = value;
                          });
                        },
                        title: const Text('Đang bán'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Hủy'),
                ),
                FilledButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }
                          final categoryId = selectedCategoryId;
                          if (categoryId == null) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Vui lòng chọn danh mục'),
                              ),
                            );
                            return;
                          }
                          final priceText =
                              priceController.text.trim().replaceAll(',', '.');
                          final price = double.tryParse(priceText);
                          if (price == null) {
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Giá không hợp lệ')),
                            );
                            return;
                          }
                          setStateDialog(() => isSubmitting = true);
                          try {
                            Map<String, dynamic>? uploadResult;
                            if (selectedImage != null) {
                              final bytes = previewBytes ??
                                  await selectedImage!.readAsBytes();
                              uploadResult = await _orderService.uploadItemImage(
                                bytes,
                                selectedImage!.name,
                              );
                            }
                            final imagePath = uploadResult?['path'] as String?;
                            if (item == null) {
                              final newItemId = await _orderService.createItem(
                                name: nameController.text.trim(),
                                price: price,
                                categoryId: categoryId,
                                description: descriptionController.text.trim(),
                                sku: skuController.text.trim(),
                                enabled: enabled,
                                imagePath: imagePath,
                              );
                              if (uploadResult != null) {
                                final mediaIdRaw = uploadResult['media_id'];
                                final mediaId = mediaIdRaw is int
                                    ? mediaIdRaw
                                    : int.tryParse(mediaIdRaw?.toString() ?? '');
                                if (mediaId != null) {
                                  await _orderService.setItemImage(
                                    itemId: newItemId,
                                    mediaId: mediaId,
                                    imagePath: uploadResult['path'] as String?,
                                  );
                                }
                              }
                              messenger.showSnackBar(
                                const SnackBar(
                                    content: Text('Đã thêm món mới thành công')),
                              );
                            } else {
                              await _orderService.updateItem(
                                id: item.id,
                                name: nameController.text.trim(),
                                price: price,
                                categoryId: categoryId,
                                description: descriptionController.text.trim(),
                                sku: skuController.text.trim(),
                                enabled: enabled,
                                taxRate: item.taxRate,
                                stationId: item.stationId,
                                imagePath: imagePath,
                              );
                              if (uploadResult != null) {
                                final mediaIdRaw = uploadResult['media_id'];
                                final mediaId = mediaIdRaw is int
                                    ? mediaIdRaw
                                    : int.tryParse(mediaIdRaw?.toString() ?? '');
                                if (mediaId != null) {
                                  await _orderService.setItemImage(
                                    itemId: item.id,
                                    mediaId: mediaId,
                                    imagePath: uploadResult['path'] as String?,
                                  );
                                }
                              }
                              messenger.showSnackBar(
                                const SnackBar(
                                    content: Text('Đã cập nhật món ăn')),
                              );
                            }
                            if (Navigator.of(dialogContext).canPop()) {
                              Navigator.of(dialogContext).pop(true);
                            }
                          } on ApiException catch (error) {
                            messenger.showSnackBar(
                              SnackBar(content: Text(error.message)),
                            );
                            setStateDialog(() => isSubmitting = false);
                          } catch (error) {
                            messenger.showSnackBar(
                              SnackBar(
                                  content: Text('Không thể lưu món: $error')),
                            );
                            setStateDialog(() => isSubmitting = false);
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(item == null ? 'Thêm' : 'Lưu'),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldReload == true) {
      _loadItems();
    }
  }

  Future<void> _deleteItem(MenuItem item) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa món ăn'),
          content: Text('Bạn có chắc muốn xóa món "${item.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await _orderService.deleteItem(item.id);
        messenger.showSnackBar(
          const SnackBar(content: Text('Đã xóa món ăn')), 
        );
        _loadItems();
      } on ApiException catch (error) {
        messenger.showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      } catch (error) {
        messenger.showSnackBar(
          SnackBar(content: Text('Không thể xóa món: $error')),
        );
      }
    }
  }

  Future<void> _toggleItemStatus(MenuItem item) async {
    final messenger = ScaffoldMessenger.of(context);
    final categoryId = item.categoryId;
    if (categoryId == null) {
      messenger.showSnackBar(
        SnackBar(content: Text('Không xác định được danh mục của món ${item.name}')),
      );
      return;
    }
    try {
      await _orderService.updateItem(
        id: item.id,
        name: item.name,
        price: item.price,
        categoryId: categoryId,
        description: item.description,
        sku: item.sku,
        enabled: !item.enabled,
        taxRate: item.taxRate,
        stationId: item.stationId,
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(item.enabled
              ? 'Đã ngưng bán món ${item.name}'
              : 'Đã mở bán món ${item.name}'),
        ),
      );
      _loadItems();
    } on ApiException catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Không thể cập nhật món: $error')),
      );
    }
  }

  Future<void> _manageItemToppings(MenuItem item) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final groups = await _modifierService.fetchGroups();
      if (!mounted) return;
      if (groups.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Chưa có nhóm topping. Vui lòng tạo trong mục Topping.')),
        );
        return;
      }
      final assignedIds = await _modifierService.fetchItemGroupIds(item.id);
      if (!mounted) return;
      final selected = assignedIds.toSet();

      final saved = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          bool isSaving = false;
          return StatefulBuilder(
            builder: (context, setStateSheet) {
              Future<void> submit() async {
                setStateSheet(() => isSaving = true);
                try {
                  final orderedIds = groups
                      .where((group) => selected.contains(group.id))
                      .map((group) => group.id)
                      .toList();
                  await _modifierService.updateItemGroups(
                    itemId: item.id,
                    groupIds: orderedIds,
                  );
                  if (context.mounted) Navigator.pop(context, true);
                } on ApiException catch (error) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(error.message)),
                  );
                } catch (error) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Không thể lưu topping: $error')),
                  );
                } finally {
                  if (context.mounted) {
                    setStateSheet(() => isSaving = false);
                  }
                }
              }

              String _groupDescription(ModifierGroup group) {
                final parts = <String>[];
                parts.add('Tối thiểu ${group.minSelect}');
                if (group.maxSelect != null && group.maxSelect! > 0) {
                  parts.add('Tối đa ${group.maxSelect}');
                } else {
                  parts.add('Không giới hạn');
                }
                if (group.required) {
                  parts.add('Bắt buộc');
                }
                return parts.join(' • ');
              }

              return SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: FractionallySizedBox(
                    heightFactor: 0.7,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gán topping cho ${item.name}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Chọn các nhóm topping áp dụng cho món',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: groups.length,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            itemBuilder: (context, index) {
                              final group = groups[index];
                              return Card(
                                child: CheckboxListTile(
                                  value: selected.contains(group.id),
                                  onChanged: isSaving
                                      ? null
                                      : (value) => setStateSheet(() {
                                            if (value == true) {
                                              selected.add(group.id);
                                            } else {
                                              selected.remove(group.id);
                                            }
                                          }),
                                  title: Text(group.name),
                                  subtitle: Text(_groupDescription(group)),
                                ),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: isSaving ? null : submit,
                              icon: const Icon(Icons.save_outlined),
                              label: Text(isSaving ? 'Đang lưu...' : 'Lưu thay đổi'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );

      if (saved == true && mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Đã cập nhật topping cho món ${item.name}')),
        );
      }
    } on ApiException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Không thể tải danh sách topping: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý món ăn')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showItemDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Thêm món'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Tìm kiếm món',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _loadItems();
                              },
                            ),
                    ),
                    onSubmitted: (_) => _loadItems(),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _statusFilter,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _statusFilter = value;
                    });
                    _loadItems();
                  },
                  items: const [
                    DropdownMenuItem(
                      value: 'active',
                      child: Text('Đang bán'),
                    ),
                    DropdownMenuItem(
                      value: 'inactive',
                      child: Text('Ngưng bán'),
                    ),
                    DropdownMenuItem(
                      value: 'all',
                      child: Text('Tất cả'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            height: 64,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              scrollDirection: Axis.horizontal,
              children: [
                ChoiceChip(
                  label: const Text('Tất cả'),
                  selected: _selectedCategory == null,
                  onSelected: (_) => _onCategorySelected(null),
                ),
                ..._categories.map(
                  (category) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(category.name),
                      selected: _selectedCategory?.id == category.id,
                      onSelected: (_) => _onCategorySelected(category),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _loadItems();
                await _itemsFuture;
              },
              child: FutureBuilder<List<MenuItem>>(
                future: _itemsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text('Lỗi: ${snapshot.error}'),
                        ),
                      ],
                    );
                  }
                  final items = snapshot.data ?? [];
                  if (items.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 48),
                        Center(child: Text('Không có món ăn.')),
                      ],
                    );
                  }
                  final currency = NumberFormat.currency(
                    locale: 'vi_VN',
                    symbol: '₫',
                    decimalDigits: 0,
                  );
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final statusColor = item.enabled
                          ? Colors.green.shade100
                          : Colors.orange.shade100;
                      final statusText = item.enabled ? 'Đang bán' : 'Ngưng bán';
                      return Card(
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 56,
                              height: 56,
                              child: item.imageUrl != null
                                  ? Image.network(
                                      item.imageUrl!,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceVariant,
                                      child: const Icon(Icons.fastfood_outlined),
                                    ),
                            ),
                          ),
                          title: Text(item.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Danh mục: ${_categoryLabelFor(item)}'),
                              Text('Giá: ${currency.format(item.price)}'),
                              if (item.sku != null && item.sku!.isNotEmpty)
                                Text('SKU: ${item.sku}'),
                              if (item.description != null &&
                                  item.description!.isNotEmpty)
                                Text(
                                  item.description!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: 6),
                              Chip(
                                label: Text(statusText),
                                backgroundColor: statusColor,
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showItemDialog(item: item);
                              } else if (value == 'delete') {
                                _deleteItem(item);
                              } else if (value == 'toggle') {
                                _toggleItemStatus(item);
                              } else if (value == 'toppings') {
                                _manageItemToppings(item);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: ListTile(
                                  dense: true,
                                  leading: Icon(Icons.edit_outlined),
                                  title: Text('Chỉnh sửa'),
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'toppings',
                                child: ListTile(
                                  dense: true,
                                  leading: Icon(Icons.icecream_outlined),
                                  title: Text('Quản lý topping'),
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'toggle',
                                child: ListTile(
                                  dense: true,
                                  leading: Icon(Icons.swap_horiz),
                                  title: Text('Đổi trạng thái'),
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  dense: true,
                                  leading: Icon(Icons.delete_outline),
                                  title: Text('Xóa'),
                                ),
                              ),
                            ],
                          ),
                          onTap: () => _showItemDialog(item: item),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
