import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/currency.dart';
import '../../../core/providers/documents_directory_provider.dart';
import '../../../domain/models/menu_item.dart';
import '../controllers/menu_admin_controller.dart';

class MenuAdminPage extends ConsumerWidget {
  const MenuAdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(menuAdminControllerProvider);
    ref.listen<MenuAdminState>(menuAdminControllerProvider, (previous, next) {
      if (previous?.errorMessage != next.errorMessage &&
          next.errorMessage != null &&
          next.errorMessage!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý menu'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: state.isSubmitting
            ? null
            : () => _showMenuItemForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Thêm món'),
      ),
      body: Stack(
        children: [
          if (state.isLoading && state.items.isEmpty)
            const Center(child: CircularProgressIndicator())
          else
            RefreshIndicator(
              onRefresh: () async {
                await ref
                    .read(menuAdminControllerProvider.notifier)
                    .loadItems();
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  if (state.items.isEmpty) {
                    return const SizedBox(
                      height: 120,
                      child: Center(child: Text('Chưa có món nào.')),
                    );
                  }
                  final item = state.items[index];
                  return _MenuAdminListTile(
                    item: item,
                    isBusy: state.isSubmitting,
                    onEdit: () => _showMenuItemForm(context, ref, item: item),
                    onToggle: (value) => _toggleItem(context, ref, item, value),
                  );
                },
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemCount: state.items.isEmpty ? 1 : state.items.length,
              ),
            ),
          if ((state.isLoading && state.items.isNotEmpty) || state.isSubmitting)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(minHeight: 3),
            ),
        ],
      ),
    );
  }

  Future<void> _toggleItem(
    BuildContext context,
    WidgetRef ref,
    MenuItem item,
    bool isActive,
  ) async {
    final success = await ref
        .read(menuAdminControllerProvider.notifier)
        .toggleItem(item.id, isActive);
    if (!context.mounted) {
      return;
    }
    final message = success
        ? 'Đã ${isActive ? 'mở bán' : 'ngưng bán'} "${item.name}".'
        : ref.read(menuAdminControllerProvider).errorMessage ??
            'Không thể cập nhật trạng thái.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showMenuItemForm(
    BuildContext context,
    WidgetRef ref, {
    MenuItem? item,
  }) async {
    final result = await showDialog<_MenuItemFormResult>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _MenuItemFormDialog(initial: item);
      },
    );

    if (result == null) {
      return;
    }

    final controller = ref.read(menuAdminControllerProvider.notifier);
    final success = item == null
        ? await controller.createItem(
            name: result.name,
            category: result.category,
            price: result.price,
            isActive: result.isActive,
            imagePath: result.imagePath,
          )
        : await controller.updateItem(
            item.copyWith(
              name: result.name,
              category: result.category,
              price: result.price,
              isActive: result.isActive,
              imagePath: result.imagePath,
            ),
          );

    if (!context.mounted) {
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    if (success) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(item == null ? 'Đã thêm món mới.' : 'Đã cập nhật món.'),
        ),
      );
    } else {
      final message =
          ref.read(menuAdminControllerProvider).errorMessage ?? 'Đã có lỗi xảy ra.';
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}

class _MenuAdminListTile extends ConsumerWidget {
  const _MenuAdminListTile({
    required this.item,
    required this.onEdit,
    required this.onToggle,
    required this.isBusy,
  });

  final MenuItem item;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggle;
  final bool isBusy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsDirectory = ref.watch(documentsDirectoryProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 72,
                height: 72,
                child: _MenuImagePreview(
                  imagePath: item.imagePath,
                  documentsDirectory: documentsDirectory,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.category,
                    style: textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
                  ),
                  const SizedBox(height: 4),
                  Text('Giá: ${formatVND(item.price)}'),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text('Đang bán'),
                          const SizedBox(width: 8),
                          Switch.adaptive(
                            value: item.isActive,
                            onChanged: isBusy ? null : onToggle,
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: isBusy ? null : onEdit,
                        icon: const Icon(Icons.edit),
                        label: const Text('Chỉnh sửa'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuImagePreview extends StatelessWidget {
  const _MenuImagePreview({required this.imagePath, required this.documentsDirectory});

  final String? imagePath;
  final AsyncValue<String> documentsDirectory;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (imagePath == null || imagePath!.isEmpty) {
      return Container(
        color: colorScheme.surfaceVariant,
        alignment: Alignment.center,
        child: Icon(
          Icons.image_not_supported_outlined,
          color: colorScheme.outline,
        ),
      );
    }

    if (imagePath!.startsWith('assets/')) {
      return Image.asset(
        imagePath!,
        fit: BoxFit.cover,
      );
    }

      return documentsDirectory.when(
        data: (dir) {
          final file = File(p.join(dir, imagePath!));
          if (!file.existsSync()) {
            return Container(
              color: colorScheme.surfaceVariant,
              alignment: Alignment.center,
            child: Icon(
              Icons.broken_image_outlined,
              color: colorScheme.outline,
            ),
            );
          }
          return Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: colorScheme.surfaceVariant,
                alignment: Alignment.center,
                child: Icon(
                  Icons.broken_image_outlined,
                  color: colorScheme.outline,
                ),
              );
            },
          );
        },
        loading: () => Container(
          color: colorScheme.surfaceVariant,
          alignment: Alignment.center,
          child: const SizedBox(
            width: 20,
            height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (error, stackTrace) => Container(
        color: colorScheme.surfaceVariant,
        alignment: Alignment.center,
        child: Icon(
          Icons.broken_image_outlined,
          color: colorScheme.error,
        ),
      ),
    );
  }
}

class _MenuItemFormDialog extends StatefulWidget {
  const _MenuItemFormDialog({this.initial});

  final MenuItem? initial;

  @override
  State<_MenuItemFormDialog> createState() => _MenuItemFormDialogState();
}

class _MenuItemFormDialogState extends State<_MenuItemFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _priceController;
  bool _isActive = true;
  String? _imagePath;
  String? _documentsDir;
  bool _isSavingImage = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.name ?? '');
    _categoryController =
        TextEditingController(text: widget.initial?.category ?? '');
    _priceController = TextEditingController(
      text: widget.initial != null
          ? widget.initial!.price.toStringAsFixed(0)
          : '',
    );
    _isActive = widget.initial?.isActive ?? true;
    _imagePath = widget.initial?.imagePath;
    _loadDocumentsDir();
  }

  Future<void> _loadDocumentsDir() async {
    final dir = await getApplicationDocumentsDirectory();
    if (!mounted) {
      return;
    }
    setState(() {
      _documentsDir = dir.path;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Thêm món' : 'Chỉnh sửa món'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Tên món'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Tên món không được để trống';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Danh mục'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Danh mục không được để trống';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Giá bán'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Giá bán không được để trống';
                  }
                  final parsed = double.tryParse(value.replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0) {
                    return 'Giá bán phải lớn hơn 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                title: const Text('Đang bán'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Ảnh minh hoạ',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 8),
              AspectRatio(
                aspectRatio: 4 / 3,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _buildImagePreview(),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _isSavingImage ? null : _pickImage,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(_isSavingImage ? 'Đang xử lý ảnh...' : 'Chọn ảnh'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Huỷ'),
        ),
        FilledButton(
          onPressed: _isSavingImage ? null : _submit,
          child: const Text('Lưu'),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    if (_imagePath == null || _imagePath!.isEmpty) {
      return const ColoredBox(
        color: Color(0x11000000),
        child: Center(child: Icon(Icons.image_outlined, size: 48)),
      );
    }

    if (_imagePath!.startsWith('assets/')) {
      return Image.asset(
        _imagePath!,
        fit: BoxFit.cover,
      );
    }

    if (_documentsDir == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final file = File(p.join(_documentsDir!, _imagePath!));
    if (!file.existsSync()) {
      return const Center(child: Icon(Icons.broken_image_outlined, size: 48));
    }

    return Image.file(
      file,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          const Center(child: Icon(Icons.broken_image_outlined, size: 48)),
    );
  }

  Future<void> _pickImage() async {
    setState(() {
      _isSavingImage = true;
    });
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) {
        return;
      }
      final documentsDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(documentsDir.path, 'menu_images'));
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${p.basename(picked.path)}';
      final savedPath = p.join(imagesDir.path, fileName);
      await File(picked.path).copy(savedPath);
      if (!mounted) {
        return;
      }
      setState(() {
        _imagePath = p.join('menu_images', fileName);
        _documentsDir = documentsDir.path;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSavingImage = false;
        });
      }
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final parsedPrice = double.parse(_priceController.text.replaceAll(',', '.'));
    Navigator.of(context).pop(
      _MenuItemFormResult(
        name: _nameController.text.trim(),
        category: _categoryController.text.trim(),
        price: parsedPrice,
        isActive: _isActive,
        imagePath: _imagePath,
      ),
    );
  }
}

class _MenuItemFormResult {
  const _MenuItemFormResult({
    required this.name,
    required this.category,
    required this.price,
    required this.isActive,
    required this.imagePath,
  });

  final String name;
  final String category;
  final double price;
  final bool isActive;
  final String? imagePath;
}
