import 'package:flutter/material.dart';

import '../models/area.dart';
import '../models/table.dart';
import '../services/api_service.dart';
import '../services/order_service.dart';

/// Screen for admin users to manage dining tables.
class TablesScreen extends StatefulWidget {
  const TablesScreen({super.key});

  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> {
  final _orderService = OrderService.instance;
  List<Area> _areas = const [];
  int? _selectedAreaId;
  late Future<List<DiningTable>> _tablesFuture =
      Future.value(const <DiningTable>[]);
  bool _loadingAreas = true;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loadingAreas = true;
    });
    try {
      final areas = await _orderService.fetchAreas();
      setState(() {
        _areas = areas;
        _selectedAreaId = areas.isNotEmpty ? areas.first.id : null;
        _tablesFuture = _orderService.fetchTables(areaId: _selectedAreaId);
        _loadingAreas = false;
      });
    } on ApiException catch (error) {
      setState(() {
        _areas = const [];
        _selectedAreaId = null;
        _tablesFuture = Future.value(const <DiningTable>[]);
        _loadingAreas = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } catch (error) {
      setState(() {
        _areas = const [];
        _selectedAreaId = null;
        _tablesFuture = Future.value(const <DiningTable>[]);
        _loadingAreas = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tải danh sách khu: $error')),
        );
      }
    }
  }

  Future<void> _reloadTables() async {
    final future = _orderService.fetchTables(areaId: _selectedAreaId);
    setState(() {
      _tablesFuture = future;
    });
    await future;
  }

  void _onFilterChanged(int? areaId) {
    setState(() {
      _selectedAreaId = areaId;
      _tablesFuture = _orderService.fetchTables(areaId: areaId);
    });
  }

  Future<void> _deleteTable(DiningTable table) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa bàn'),
          content: Text('Bạn có chắc muốn xóa bàn "${table.name}"?'),
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
      await _orderService.deleteTable(table.id);
      messenger.showSnackBar(
        const SnackBar(content: Text('Đã xóa bàn thành công')),
      );
      await _reloadTables();
    } on ApiException catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Không thể xóa bàn: $error')),
      );
    }
  }

  Future<void> _showTableDialog({DiningTable? table}) async {
    if (_areas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng tạo khu bàn trước khi thêm bàn mới')),
      );
      return;
    }

    final nameController = TextEditingController(text: table?.name ?? '');
    final codeController = TextEditingController(text: table?.code ?? '');
    final numberController = TextEditingController(
      text: table?.number != null ? table!.number.toString() : '',
    );
    final capacityController = TextEditingController(
      text: table?.capacity != null ? table!.capacity.toString() : '',
    );
    final formKey = GlobalKey<FormState>();
    final messenger = ScaffoldMessenger.of(context);
    int? areaId = table?.areaId ?? _selectedAreaId ?? _areas.first.id;
    final statuses = <String, String>{
      'free': 'Trống',
      'occupied': 'Đang dùng',
      'cleaning': 'Đang dọn',
    };
    String status = statuses.containsKey(table?.status ?? '')
        ? table!.status!
        : 'free';

    final shouldReload = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(table == null ? 'Thêm bàn mới' : 'Chỉnh sửa bàn'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<int>(
                        value: areaId,
                        items: _areas
                            .map(
                              (area) => DropdownMenuItem<int>(
                                value: area.id,
                                child: Text(area.displayLabel),
                              ),
                            )
                            .toList(),
                        onChanged: isSubmitting
                            ? null
                            : (value) {
                                setStateDialog(() {
                                  areaId = value;
                                });
                              },
                        decoration: const InputDecoration(
                          labelText: 'Thuộc khu',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Tên bàn',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập tên bàn';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: codeController,
                        decoration: const InputDecoration(
                          labelText: 'Mã bàn (tùy chọn)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: numberController,
                        decoration: const InputDecoration(
                          labelText: 'Số thứ tự (tùy chọn)',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: capacityController,
                        decoration: const InputDecoration(
                          labelText: 'Sức chứa (tùy chọn)',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: status,
                        items: statuses.entries
                            .map(
                              (entry) => DropdownMenuItem<String>(
                                value: entry.key,
                                child: Text(entry.value),
                              ),
                            )
                            .toList(),
                        onChanged: isSubmitting
                            ? null
                            : (value) {
                                if (value == null) return;
                                setStateDialog(() {
                                  status = value;
                                });
                              },
                        decoration: const InputDecoration(
                          labelText: 'Trạng thái',
                        ),
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
                          if (areaId == null) {
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Vui lòng chọn khu bàn')), 
                            );
                            return;
                          }
                          final name = nameController.text.trim();
                          final code = codeController.text.trim();
                          final number =
                              int.tryParse(numberController.text.trim());
                          final capacity =
                              int.tryParse(capacityController.text.trim());

                          setStateDialog(() => isSubmitting = true);
                          try {
                            if (table == null) {
                              await _orderService.createTable(
                                areaId: areaId!,
                                name: name,
                                code: code,
                                number: number,
                                capacity: capacity,
                                status: status,
                              );
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Đã thêm bàn mới')), 
                              );
                            } else {
                              await _orderService.updateTable(
                                id: table.id,
                                areaId: areaId!,
                                name: name,
                                code: code,
                                number: number,
                                capacity: capacity,
                                status: status,
                              );
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Đã cập nhật thông tin bàn')), 
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
                              SnackBar(content: Text('Không thể lưu bàn: $error')),
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
                      : Text(table == null ? 'Thêm' : 'Lưu'),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldReload == true) {
      await _reloadTables();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý bàn ăn')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTableDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Thêm bàn'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: _selectedAreaId,
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Tất cả khu'),
                      ),
                      ..._areas.map(
                        (area) => DropdownMenuItem<int?>(
                          value: area.id,
                          child: Text(area.displayLabel),
                        ),
                      ),
                    ],
                    onChanged: _loadingAreas
                        ? null
                        : (value) {
                            _onFilterChanged(value);
                          },
                    decoration: const InputDecoration(
                      labelText: 'Lọc theo khu',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _loadingAreas
                      ? null
                      : () {
                          _loadInitial();
                        },
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Làm mới khu bàn',
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await _reloadTables();
              },
              child: FutureBuilder<List<DiningTable>>(
                future: _tablesFuture,
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
                  final tables = snapshot.data ?? [];
                  if (tables.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 48),
                        Center(child: Text('Chưa có bàn nào.')), 
                      ],
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: tables.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final table = tables[index];
                      final statusLabel = table.status == 'occupied'
                          ? 'Đang dùng'
                          : table.status == 'cleaning'
                              ? 'Đang dọn'
                              : 'Trống';
                      final statusColor = table.status == 'occupied'
                          ? Colors.redAccent
                          : table.status == 'cleaning'
                              ? Colors.orange
                              : Colors.green;
                      return Card(
                        child: ListTile(
                          title: Text(table.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (table.areaName != null)
                                Text('Khu: ${table.areaName}'),
                              if (table.code != null && table.code!.isNotEmpty)
                                Text('Mã bàn: ${table.code}'),
                              if (table.number != null)
                                Text('Số thứ tự: ${table.number}'),
                              if (table.capacity != null)
                                Text('Sức chứa: ${table.capacity}'),
                              const SizedBox(height: 4),
                              Chip(
                                label: Text(statusLabel),
                                backgroundColor: statusColor.withOpacity(0.1),
                                labelStyle: TextStyle(color: statusColor),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showTableDialog(table: table);
                              } else if (value == 'delete') {
                                _deleteTable(table);
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
                          onTap: () => _showTableDialog(table: table),
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

