import 'package:flutter/material.dart';

import '../models/area.dart';
import '../models/table.dart';
import '../services/api_service.dart';
import '../services/order_service.dart';
import 'order_detail_screen.dart';
import '../widgets/table_tile.dart';

/// Screen where cashier selects an area and table before creating an order.
class TableSelectScreen extends StatefulWidget {
  const TableSelectScreen({super.key});

  @override
  State<TableSelectScreen> createState() => _TableSelectScreenState();
}

class _TableSelectScreenState extends State<TableSelectScreen> {
  final _orderService = OrderService.instance;
  List<Area> _areas = const [];
  int? _selectedAreaId;
  String _statusFilter = 'all';
  late Future<List<DiningTable>> _tablesFuture = Future.value(const []);
  final _customerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAreas();
  }

  @override
  void dispose() {
    _customerController.dispose();
    super.dispose();
  }

  Future<void> _loadAreas() async {
    try {
      final areas = await _orderService.fetchAreas();
      if (!mounted) return;
      _statusFilter = 'all';
      final areaId = areas.isNotEmpty ? areas.first.id : null;
      setState(() {
        _areas = areas;
        _selectedAreaId = areaId;
        _tablesFuture = _fetchTablesFuture();
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<List<DiningTable>> _fetchTablesFuture() {
    final areaId = _selectedAreaId;
    if (areaId == null) return Future.value(const []);
    final status = _statusFilter == 'all' ? null : _statusFilter;
    return _orderService.fetchTables(areaId: areaId, status: status);
  }

  Future<void> _reloadTables() async {
    final future = _fetchTablesFuture();
    setState(() {
      _tablesFuture = future;
    });
    await future;
  }

  void _onAreaSelected(int areaId) {
    setState(() {
      _selectedAreaId = areaId;
      _tablesFuture = _fetchTablesFuture();
    });
  }

  void _onStatusSelected(String status) {
    if (_statusFilter == status) return;
    setState(() {
      _statusFilter = status;
      _tablesFuture = _fetchTablesFuture();
    });
  }

  Future<void> _handleTableTap(DiningTable table) async {
    final status = table.status ?? 'free';
    if (status == 'free') {
      await _showCreateOrderDialog(table);
      return;
    }
    if (status == 'occupied') {
      if (table.openOrderId != null) {
        await _openOrderDetail(table.openOrderId!, table.name);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không tìm thấy order đang mở cho ${table.name}')),
        );
      }
      return;
    }
    await _showStatusChangeSheet(table);
  }

  Future<void> _showCreateOrderDialog(DiningTable table) async {
    _customerController.clear();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Tạo order cho bàn ${table.name}?'),
          content: TextField(
            controller: _customerController,
            decoration: const InputDecoration(
              labelText: 'Tên khách hàng (tuỳ chọn)',
            ),
            textInputAction: TextInputAction.done,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Tạo order'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    final customerName = _customerController.text.trim();
    try {
      final order = await _orderService.createOrder(
        tableId: table.id,
        customerName: customerName.isEmpty ? null : customerName,
      );
      if (!mounted) return;
      await _openOrderDetail(order.id, table.name);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tạo order: $error')),
      );
    }
  }

  Future<void> _openOrderDetail(int orderId, String tableName) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(orderId: orderId, tableName: tableName),
      ),
    );
    if (!mounted) return;
    await _reloadTables();
  }

  Future<void> _setTableStatus(DiningTable table, String status) async {
    if (status == table.status) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _orderService.updateTableStatus(tableId: table.id, status: status);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Đã cập nhật ${table.name} sang trạng thái ${_statusLabel(status)}')),
      );
      await _reloadTables();
    } on ApiException catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Không thể cập nhật trạng thái: $error')),
      );
    }
  }

  Future<void> _showStatusChangeSheet(DiningTable table) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: Text(
                  'Đổi trạng thái ${table.name}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ...['free', 'occupied', 'cleaning'].map(
                (status) => ListTile(
                  leading: Icon(_statusIcon(status)),
                  title: Text(_statusLabel(status)),
                  trailing: status == table.status
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () => Navigator.pop(context, status),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
    if (result == null) return;
    await _setTableStatus(table, result);
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'free':
        return 'Trống';
      case 'occupied':
        return 'Đang dùng';
      case 'cleaning':
        return 'Đang dọn';
      default:
        return status;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'occupied':
        return Icons.event_seat;
      case 'cleaning':
        return Icons.cleaning_services;
      default:
        return Icons.table_bar;
    }
  }

  Color _statusColor(String status, ColorScheme colors) {
    switch (status) {
      case 'occupied':
        return colors.error;
      case 'cleaning':
        return colors.tertiary;
      default:
        return colors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 900 ? 4 : width > 600 ? 3 : 2;
    final colorScheme = Theme.of(context).colorScheme;
    final areaChips = _areas.map((area) {
      final id = area.id;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(area.displayLabel),
          selected: _selectedAreaId == id,
          onSelected: (_) => _onAreaSelected(id),
        ),
      );
    }).toList();

    final statusFilters = <Widget>[
      for (final entry in [
        const MapEntry('all', 'Tất cả'),
        const MapEntry('free', 'Trống'),
        const MapEntry('occupied', 'Đang dùng'),
        const MapEntry('cleaning', 'Đang dọn'),
      ])
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(entry.value),
            selected: _statusFilter == entry.key,
            onSelected: (_) => _onStatusSelected(entry.key),
          ),
        ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Chọn bàn phục vụ')),
      body: Column(
        children: [
          SizedBox(
            height: 72,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              scrollDirection: Axis.horizontal,
              children: areaChips,
            ),
          ),
          SizedBox(
            height: 56,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: statusFilters,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Chạm để order hoặc xem chi tiết. Nhấn giữ hoặc dùng nút ⋮ để đổi trạng thái bàn.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _reloadTables,
              child: FutureBuilder<List<DiningTable>>(
                future: _tablesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
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
                    final message = _statusFilter == 'all'
                        ? 'Không có bàn trong khu vực này.'
                        : 'Không có bàn với trạng thái đã chọn.';
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 48),
                        Center(child: Text(message)),
                      ],
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 1,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemBuilder: (context, index) {
                      final table = tables[index];
                      final status = table.status ?? 'free';
                      final statusColor = _statusColor(status, colorScheme);
                      return TableTile(
                        table: table,
                        statusLabel: _statusLabel(status),
                        statusColor: statusColor,
                        onTap: () => _handleTableTap(table),
                        onLongPress: () => _showStatusChangeSheet(table),
                        trailing: PopupMenuButton<String>(
                          tooltip: 'Đổi trạng thái bàn',
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.more_vert, size: 20),
                          onSelected: (value) => _setTableStatus(table, value),
                          itemBuilder: (context) {
                            return [
                              for (final statusOption in ['free', 'occupied', 'cleaning'])
                                PopupMenuItem<String>(
                                  value: statusOption,
                                  enabled: table.status != statusOption,
                                  child: Text(_statusLabel(statusOption)),
                                ),
                            ];
                          },
                        ),
                      );
                    },
                    itemCount: tables.length,
                    physics: const AlwaysScrollableScrollPhysics(),
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
