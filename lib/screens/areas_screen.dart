import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/area.dart';
import '../services/api_service.dart';
import '../services/order_service.dart';

/// Screen that allows admin users to manage dining areas.
class AreasScreen extends StatefulWidget {
  const AreasScreen({super.key});

  @override
  State<AreasScreen> createState() => _AreasScreenState();
}

class _AreasScreenState extends State<AreasScreen> {
  final _orderService = OrderService.instance;
  late Future<List<Area>> _future;

  @override
  void initState() {
    super.initState();
    _future = _orderService.fetchAreas();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _orderService.fetchAreas();
    });
    await _future;
  }

  Future<void> _deleteArea(Area area) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa khu vực'),
          content: Text('Bạn có chắc muốn xóa khu "${area.displayLabel}"?'),
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
    if (confirmed != true) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await _orderService.deleteArea(area.id);
      messenger.showSnackBar(
        const SnackBar(content: Text('Đã xóa khu vực')), 
      );
      await _reload();
    } on ApiException catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Không thể xóa khu vực: $error')),
      );
    }
  }

  Future<void> _showAreaDialog({Area? area}) async {
    final nameController = TextEditingController(text: area?.name ?? '');
    final codeController = TextEditingController(text: area?.code ?? '');
    final sortController = TextEditingController(
      text: area?.sort != null ? area!.sort.toString() : '',
    );
    final formKey = GlobalKey<FormState>();
    final messenger = ScaffoldMessenger.of(context);
    final picker = ImagePicker();
    XFile? selectedImage;
    Uint8List? previewBytes;
    String? previewUrl = area?.imageUrl;

    final shouldReload = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future<void> handlePick() async {
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
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(content: Text('Không thể chọn ảnh: $error')),
                );
              }
            }

            return AlertDialog(
              title: Text(area == null ? 'Thêm khu vực mới' : 'Chỉnh sửa khu vực'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                          color: Theme.of(context).colorScheme.surfaceVariant,
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
                                  onPressed: isSubmitting ? null : handlePick,
                                  icon: const Icon(Icons.photo_library_outlined),
                                  label: Text(previewBytes == null && previewUrl == null
                                      ? 'Chọn ảnh đại diện'
                                      : 'Đổi ảnh'),
                                ),
                                if (previewBytes != null || previewUrl != null)
                                  Text(
                                    'Ảnh sẽ hiển thị trong danh sách khu vực',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Tên khu vực',
                        ),
                        autofocus: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập tên khu vực';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: codeController,
                        decoration: const InputDecoration(
                          labelText: 'Mã khu (tùy chọn)',
                        ),
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
                          final code = codeController.text.trim();
                          final sort = int.tryParse(sortController.text.trim());

                          setStateDialog(() => isSubmitting = true);
                          try {
                            Map<String, dynamic>? uploadResult;
                            if (selectedImage != null) {
                              final bytes = previewBytes ?? await selectedImage!.readAsBytes();
                              uploadResult = await _orderService.uploadAreaImage(bytes, selectedImage!.name);
                            }

                            if (area == null) {
                              final newId = await _orderService.createArea(
                                name: name,
                                code: code,
                                sort: sort,
                                imagePath: uploadResult?['path'] as String?,
                              );
                              if (uploadResult != null) {
                                final mediaIdRaw = uploadResult['media_id'];
                                final mediaId = mediaIdRaw is int
                                    ? mediaIdRaw
                                    : int.tryParse(mediaIdRaw?.toString() ?? '');
                                if (mediaId != null) {
                                  await _orderService.setAreaImage(
                                    areaId: newId,
                                    mediaId: mediaId,
                                    imagePath: uploadResult['path'] as String?,
                                  );
                                }
                              }
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Đã thêm khu vực mới')), 
                              );
                            } else {
                              await _orderService.updateArea(
                                id: area.id,
                                name: name,
                                code: code,
                                sort: sort,
                                imagePath: uploadResult?['path'] as String?,
                              );
                              if (uploadResult != null) {
                                final mediaIdRaw = uploadResult['media_id'];
                                final mediaId = mediaIdRaw is int
                                    ? mediaIdRaw
                                    : int.tryParse(mediaIdRaw?.toString() ?? '');
                                if (mediaId != null) {
                                  await _orderService.setAreaImage(
                                    areaId: area.id,
                                    mediaId: mediaId,
                                    imagePath: uploadResult['path'] as String?,
                                  );
                                }
                              }
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Đã cập nhật khu vực')), 
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
                              SnackBar(content: Text('Không thể lưu khu vực: $error')),
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
                      : Text(area == null ? 'Thêm' : 'Lưu'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý khu bàn')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAreaDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Thêm khu'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _reload();
        },
        child: FutureBuilder<List<Area>>(
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
            final areas = snapshot.data ?? [];
            if (areas.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 48),
                  Center(child: Text('Chưa có khu vực nào.')), 
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: areas.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final area = areas[index];
                return Card(
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: area.imageUrl != null
                            ? Image.network(area.imageUrl!, fit: BoxFit.cover)
                            : Container(
                                color: Theme.of(context).colorScheme.surfaceVariant,
                                child: const Icon(Icons.map_outlined),
                              ),
                      ),
                    ),
                    title: Text(area.displayLabel),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (area.code != null && area.code!.isNotEmpty)
                          Text('Mã khu: ${area.code}'),
                        if (area.sort != null)
                          Text('Thứ tự: ${area.sort}'),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showAreaDialog(area: area);
                        } else if (value == 'delete') {
                          _deleteArea(area);
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
                    onTap: () => _showAreaDialog(area: area),
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

