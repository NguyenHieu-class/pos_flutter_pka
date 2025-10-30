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
      setState(() {
        _areas = areas;
        if (areas.isNotEmpty) {
          _selectedAreaId = areas.first.id;
          _tablesFuture = _orderService.fetchTables(
            areaId: _selectedAreaId!,
            status: 'free',
          );
        }
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  void _onAreaSelected(int areaId) {
    setState(() {
      _selectedAreaId = areaId;
      _tablesFuture = _orderService.fetchTables(areaId: areaId, status: 'free');
    });
  }

  Future<void> _onTableSelected(DiningTable table) async {
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

    try {
      final order = await _orderService.createOrder(
        tableId: table.id,
        customerName: _customerController.text.trim().isEmpty
            ? null
            : _customerController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderDetailScreen(orderId: order.id, tableName: table.name),
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 900 ? 4 : width > 600 ? 3 : 2;
    return Scaffold(
      appBar: AppBar(title: const Text('Chọn bàn phục vụ')),
      body: Column(
        children: [
          SizedBox(
            height: 72,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              scrollDirection: Axis.horizontal,
              children: _areas.map((area) {
                final id = area.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(area.displayLabel),
                    selected: _selectedAreaId == id,
                    onSelected: (_) => _onAreaSelected(id),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                if (_selectedAreaId == null) return;
                setState(() {
                  _tablesFuture = _orderService.fetchTables(
                    areaId: _selectedAreaId!,
                    status: 'free',
                  );
                });
                await _tablesFuture;
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
                        Center(child: Text('Không có bàn trống.')), 
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
                      return TableTile(
                        table: table,
                        onTap: () => _onTableSelected(table),
                      );
                    },
                    itemCount: tables.length,
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
