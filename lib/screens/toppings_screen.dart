import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/modifier.dart';
import '../models/modifier_group.dart';
import '../services/api_service.dart';
import '../services/modifier_service.dart';

/// Screen for admins to manage topping groups and options.
class ToppingsScreen extends StatefulWidget {
  const ToppingsScreen({super.key});

  @override
  State<ToppingsScreen> createState() => _ToppingsScreenState();
}

class _ToppingsScreenState extends State<ToppingsScreen> {
  final _modifierService = ModifierService.instance;
  late Future<List<ModifierGroup>> _groupsFuture;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  void _loadGroups() {
    setState(() {
      _groupsFuture = _modifierService.fetchGroups();
    });
  }

  Future<void> _showGroupDialog({ModifierGroup? group}) async {
    final nameController = TextEditingController(text: group?.name ?? '');
    final minController =
        TextEditingController(text: group?.minSelect.toString() ?? '');
    final maxController = TextEditingController(
      text: group?.maxSelect != null ? group!.maxSelect.toString() : '',
    );
    final sortController = TextEditingController(
      text: group?.sort != null ? group!.sort.toString() : '',
    );
    final formKey = GlobalKey<FormState>();
    bool required = group?.required ?? false;
    final messenger = ScaffoldMessenger.of(context);

    final shouldReload = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future<void> submit() async {
              if (!formKey.currentState!.validate()) return;
              final minText = minController.text.trim();
              final maxText = maxController.text.trim();
              final sortText = sortController.text.trim();
              final minSelect = minText.isEmpty ? null : int.tryParse(minText);
              final maxSelect = maxText.isEmpty ? null : int.tryParse(maxText);
              final sort = sortText.isEmpty ? null : int.tryParse(sortText);
              if (minSelect != null && minSelect < 0) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Số lượng tối thiểu không hợp lệ')),
                );
                return;
              }
              if (maxSelect != null && maxSelect < 0) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Số lượng tối đa không hợp lệ')),
                );
                return;
              }
              setStateDialog(() => isSubmitting = true);
              try {
                if (group == null) {
                  await _modifierService.createGroup(
                    name: nameController.text.trim(),
                    minSelect: minSelect,
                    maxSelect: maxSelect,
                    required: required,
                    sort: sort,
                  );
                } else {
                  await _modifierService.updateGroup(
                    id: group.id,
                    name: nameController.text.trim(),
                    minSelect: minSelect,
                    maxSelect: maxSelect,
                    required: required,
                    sort: sort,
                  );
                }
                if (context.mounted) Navigator.of(dialogContext).pop(true);
              } on ApiException catch (error) {
                messenger.showSnackBar(SnackBar(content: Text(error.message)));
              } catch (error) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Không thể lưu nhóm: $error')),
                );
              } finally {
                if (context.mounted) {
                  setStateDialog(() => isSubmitting = false);
                }
              }
            }

            return AlertDialog(
              title: Text(group == null ? 'Thêm nhóm topping' : 'Cập nhật nhóm topping'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Tên nhóm'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập tên nhóm';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: minController,
                        decoration:
                            const InputDecoration(labelText: 'Số lựa chọn tối thiểu'),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: maxController,
                        decoration:
                            const InputDecoration(labelText: 'Số lựa chọn tối đa'),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile.adaptive(
                        value: required,
                        onChanged: isSubmitting
                            ? null
                            : (value) => setStateDialog(() => required = value),
                        title: const Text('Bắt buộc chọn ít nhất 1'),
                        contentPadding: EdgeInsets.zero,
                      ),
                      TextFormField(
                        controller: sortController,
                        decoration: const InputDecoration(labelText: 'Thứ tự hiển thị'),
                        keyboardType: TextInputType.number,
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
                  onPressed: isSubmitting ? null : submit,
                  child: Text(isSubmitting ? 'Đang lưu...' : 'Lưu'),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldReload == true) {
      _loadGroups();
      messenger.showSnackBar(
        SnackBar(
          content: Text(group == null
              ? 'Đã tạo nhóm topping thành công'
              : 'Đã cập nhật nhóm topping'),
        ),
      );
    }
  }

  Future<void> _confirmDeleteGroup(ModifierGroup group) async {
    final messenger = ScaffoldMessenger.of(context);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa nhóm topping'),
          content: Text(
              'Bạn có chắc muốn xóa nhóm "${group.name}"? Các topping bên trong cũng sẽ bị xóa.'),
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
    if (shouldDelete != true) return;

    try {
      await _modifierService.deleteGroup(group.id);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Đã xóa nhóm "${group.name}"')),
      );
      _loadGroups();
    } on ApiException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Không thể xóa nhóm: $error')),
      );
    }
  }

  Future<void> _openOptions(ModifierGroup group) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _ModifierOptionsSheet(group: group);
      },
    );
    _loadGroups();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý topping'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showGroupDialog(),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<ModifierGroup>>(
        future: _groupsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 40),
                  const SizedBox(height: 8),
                  Text('Không thể tải topping: ${snapshot.error}'),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _loadGroups,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }
          final groups = snapshot.data ?? [];
          if (groups.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.icecream_outlined, size: 48),
                  const SizedBox(height: 12),
                  const Text('Chưa có nhóm topping nào'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => _showGroupDialog(),
                    child: const Text('Tạo nhóm đầu tiên'),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: groups.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final group = groups[index];
              final optionCount = group.optionCount ?? group.options.length;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              group.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Quản lý topping',
                            onPressed: () => _openOptions(group),
                            icon: const Icon(Icons.list_alt),
                          ),
                          IconButton(
                            tooltip: 'Chỉnh sửa',
                            onPressed: () => _showGroupDialog(group: group),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: 'Xóa',
                            color: colorScheme.error,
                            onPressed: () => _confirmDeleteGroup(group),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          Chip(
                            avatar: const Icon(Icons.list, size: 16),
                            label: Text('$optionCount topping'),
                          ),
                          Chip(
                            avatar: const Icon(Icons.checklist, size: 16),
                            label: Text('Tối thiểu ${group.minSelect}'),
                          ),
                          Chip(
                            avatar: const Icon(Icons.filter_alt_outlined, size: 16),
                            label: Text(group.maxSelect != null && group.maxSelect! > 0
                                ? 'Tối đa ${group.maxSelect}'
                                : 'Không giới hạn'),
                          ),
                          Chip(
                            avatar: Icon(
                              group.required ? Icons.lock : Icons.lock_open,
                              size: 16,
                            ),
                            label: Text(group.required ? 'Bắt buộc' : 'Không bắt buộc'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ModifierOptionsSheet extends StatefulWidget {
  const _ModifierOptionsSheet({required this.group});

  final ModifierGroup group;

  @override
  State<_ModifierOptionsSheet> createState() => _ModifierOptionsSheetState();
}

class _ModifierOptionsSheetState extends State<_ModifierOptionsSheet> {
  final _modifierService = ModifierService.instance;
  late Future<List<Modifier>> _optionsFuture;
  final _currency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  void _loadOptions() {
    setState(() {
      _optionsFuture = _modifierService.fetchOptions(widget.group.id);
    });
  }

  Future<void> _showOptionDialog({Modifier? option}) async {
    final nameController = TextEditingController(text: option?.name ?? '');
    final priceController = TextEditingController(
      text: option?.price != null ? option!.price!.toStringAsFixed(0) : '',
    );
    final sortController = TextEditingController(
      text: option?.sort != null ? option!.sort.toString() : '',
    );
    final maxQtyController = TextEditingController(
      text: option?.maxQuantity != null ? option!.maxQuantity.toString() : '',
    );
    final formKey = GlobalKey<FormState>();
    bool allowQty = option?.allowQuantity ?? false;
    bool isDefault = option?.isDefault ?? false;
    final messenger = ScaffoldMessenger.of(context);

    final shouldReload = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future<void> submit() async {
              if (!formKey.currentState!.validate()) return;
              final priceText = priceController.text.trim();
              final sortText = sortController.text.trim();
              final maxQtyText = maxQtyController.text.trim();
              final price = priceText.isEmpty
                  ? null
                  : double.tryParse(priceText.replaceAll(',', '.'));
              final sort = sortText.isEmpty ? null : int.tryParse(sortText);
              final maxQty = maxQtyText.isEmpty ? null : int.tryParse(maxQtyText);
              setStateDialog(() => isSubmitting = true);
              try {
                if (option == null) {
                  await _modifierService.createOption(
                    groupId: widget.group.id,
                    name: nameController.text.trim(),
                    priceDelta: price,
                    allowQuantity: allowQty,
                    maxQuantity: maxQty,
                    isDefault: isDefault,
                    sort: sort,
                  );
                } else {
                  await _modifierService.updateOption(
                    optionId: option.id,
                    name: nameController.text.trim(),
                    priceDelta: price,
                    allowQuantity: allowQty,
                    maxQuantity: maxQty,
                    isDefault: isDefault,
                    sort: sort,
                  );
                }
                if (context.mounted) Navigator.of(dialogContext).pop(true);
              } on ApiException catch (error) {
                messenger.showSnackBar(SnackBar(content: Text(error.message)));
              } catch (error) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Không thể lưu topping: $error')),
                );
              } finally {
                if (context.mounted) {
                  setStateDialog(() => isSubmitting = false);
                }
              }
            }

            return AlertDialog(
              title: Text(option == null ? 'Thêm topping' : 'Cập nhật topping'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Tên topping'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập tên topping';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: priceController,
                        decoration: const InputDecoration(labelText: 'Giá cộng thêm'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile.adaptive(
                        value: allowQty,
                        onChanged: isSubmitting
                            ? null
                            : (value) => setStateDialog(() => allowQty = value),
                        title: const Text('Cho phép chọn số lượng'),
                        contentPadding: EdgeInsets.zero,
                      ),
                      TextFormField(
                        controller: maxQtyController,
                        decoration: const InputDecoration(labelText: 'Số lượng tối đa'),
                        keyboardType: TextInputType.number,
                        enabled: allowQty,
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile.adaptive(
                        value: isDefault,
                        onChanged: isSubmitting
                            ? null
                            : (value) => setStateDialog(() => isDefault = value),
                        title: const Text('Chọn sẵn khi thêm món'),
                        contentPadding: EdgeInsets.zero,
                      ),
                      TextFormField(
                        controller: sortController,
                        decoration: const InputDecoration(labelText: 'Thứ tự hiển thị'),
                        keyboardType: TextInputType.number,
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
                  onPressed: isSubmitting ? null : submit,
                  child: Text(isSubmitting ? 'Đang lưu...' : 'Lưu'),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldReload == true) {
      _loadOptions();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(option == null
              ? 'Đã thêm topping mới'
              : 'Đã cập nhật topping'),
        ),
      );
    }
  }

  Future<void> _deleteOption(Modifier option) async {
    final messenger = ScaffoldMessenger.of(context);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa topping'),
          content:
              Text('Bạn có chắc muốn xóa topping "${option.name}" khỏi nhóm?'),
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
    if (shouldDelete != true) return;

    try {
      await _modifierService.deleteOption(option.id);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Đã xóa topping "${option.name}"')),
      );
      _loadOptions();
    } on ApiException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Không thể xóa topping: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, controller) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Topping trong nhóm "${widget.group.name}"',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<Modifier>>(
                    future: _optionsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, size: 40),
                              const SizedBox(height: 8),
                              Text('Không thể tải topping: ${snapshot.error}'),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: _loadOptions,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Thử lại'),
                              ),
                            ],
                          ),
                        );
                      }
                      final options = snapshot.data ?? [];
                      if (options.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.local_cafe_outlined, size: 40),
                              const SizedBox(height: 12),
                              const Text('Chưa có topping nào trong nhóm này'),
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: () => _showOptionDialog(),
                                child: const Text('Thêm topping'),
                              ),
                            ],
                          ),
                        );
                      }
                      return ListView.separated(
                        controller: controller,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: options.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          if (index == options.length) {
                            return Center(
                              child: FilledButton.icon(
                                onPressed: () => _showOptionDialog(),
                                icon: const Icon(Icons.add),
                                label: const Text('Thêm topping'),
                              ),
                            );
                          }
                          final option = options[index];
                          return ListTile(
                            tileColor:
                                Theme.of(context).colorScheme.surfaceVariant,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            title: Text(option.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (option.price != null && option.price != 0)
                                  Text('Giá: ${_currency.format(option.price)}'),
                                Text(option.allowQuantity
                                    ? 'Cho phép chọn số lượng${option.maxQuantity != null ? ' (tối đa ${option.maxQuantity})' : ''}'
                                    : 'Không giới hạn số lượng'),
                                Text(option.isDefault
                                    ? 'Mặc định được chọn'
                                    : 'Không chọn mặc định'),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () => _showOptionDialog(option: option),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  onPressed: () => _deleteOption(option),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
