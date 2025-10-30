import 'package:flutter/material.dart';

import '../models/category.dart';
import '../services/order_service.dart';
import '../services/api_service.dart';

/// Screen for admins to view available categories.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _orderService = OrderService.instance;
  late Future<List<Category>> _future;

  @override
  void initState() {
    super.initState();
    _future = _orderService.fetchCategories();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _orderService.fetchCategories();
    });
    await _future;
  }

  Future<void> _showCategoryDialog({Category? category}) async {
    final nameController = TextEditingController(text: category?.name ?? '');
    final sortController = TextEditingController(
      text: category != null && category.sort != 0
          ? category.sort.toString()
          : '',
    );
    final formKey = GlobalKey<FormState>();
    final messenger = ScaffoldMessenger.of(context);

    final shouldReload = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(category == null
                  ? 'Thêm danh mục mới'
                  : 'Chỉnh sửa danh mục'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Tên danh mục',
                      ),
                      autofocus: true,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập tên danh mục';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: sortController,
                      decoration: const InputDecoration(
                        labelText: 'Thứ tự hiển thị',
                        helperText: 'Để trống nếu không sắp xếp',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop(false);
                        },
                  child: const Text('Hủy'),
                ),
                FilledButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }
                          final name = nameController.text.trim();
                          final sort = int.tryParse(sortController.text.trim());
                          setStateDialog(() => isSubmitting = true);
                          try {
                            if (category == null) {
                              await _orderService.createCategory(
                                name: name,
                                sort: sort,
                              );
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Đã thêm danh mục mới'),
                                ),
                              );
                            } else {
                              await _orderService.updateCategory(
                                id: category.id,
                                name: name,
                                sort: sort,
                              );
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Đã cập nhật danh mục'),
                                ),
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
                                content:
                                    Text('Không thể lưu danh mục: $error'),
                              ),
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
                      : Text(category == null ? 'Thêm' : 'Lưu'),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldReload == true) {
      await _reload();
    }
  }

  Future<void> _deleteCategory(Category category) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa danh mục'),
          content: Text('Bạn có chắc muốn xóa danh mục "${category.name}"?'),
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
        await _orderService.deleteCategory(category.id);
        messenger.showSnackBar(
          const SnackBar(content: Text('Đã xóa danh mục')), 
        );
        await _reload();
      } on ApiException catch (error) {
        messenger.showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      } catch (error) {
        messenger.showSnackBar(
          SnackBar(content: Text('Không thể xóa danh mục: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Danh mục món ăn')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Thêm danh mục'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _reload();
        },
        child: FutureBuilder<List<Category>>(
          future: _future,
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
            final categories = snapshot.data ?? [];
            if (categories.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 48),
                  Center(child: Text('Chưa có danh mục.')),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final category = categories[index];
                return Card(
                  child: ListTile(
                    title: Text(category.name),
                    subtitle: Text('Thứ tự: ${category.sort}'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showCategoryDialog(category: category);
                        } else if (value == 'delete') {
                          _deleteCategory(category);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            dense: true,
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Chỉnh sửa'),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            dense: true,
                            leading: Icon(Icons.delete_outline),
                            title: Text('Xóa'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
