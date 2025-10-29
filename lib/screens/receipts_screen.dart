import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';
import '../services/order_service.dart';

/// Screen showing paid receipts for administrative review.
class ReceiptsScreen extends StatefulWidget {
  const ReceiptsScreen({super.key});

  @override
  State<ReceiptsScreen> createState() => _ReceiptsScreenState();
}

class _ReceiptsScreenState extends State<ReceiptsScreen> {
  final _orderService = OrderService.instance;
  late DateTimeRange _range;
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _range = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: now,
    );
    _future = _loadReceipts();
  }

  Future<List<Map<String, dynamic>>> _loadReceipts({int page = 1}) {
    final formatter = DateFormat('yyyy-MM-dd');
    return _orderService.fetchReceipts(
      from: formatter.format(_range.start),
      to: formatter.format(_range.end),
      page: page,
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _range,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _range = picked;
        _future = _loadReceipts();
      });
    }
  }

  Future<void> _openReceipt(int id) async {
    try {
      final detail = await _orderService.fetchReceiptDetail(id);
      if (!mounted) return;
      final items = detail['items'] as List<dynamic>? ?? [];
      showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Chi tiết hoá đơn #$id'),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bàn: ${detail['table_name'] ?? '---'}'),
                  Text('Tổng tiền: '
                      '${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format((detail['total'] as num?)?.toDouble() ?? 0)}'),
                  const Divider(),
                  ...items.map(
                    (item) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(item['name'].toString()),
                      trailing: Text('x${item['qty'] ?? item['quantity']}'),
                      subtitle: Text(
                        NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
                            .format((item['price'] as num?)?.toDouble() ?? 0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          );
        },
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Không thể tải hóa đơn: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hóa đơn đã thanh toán'),
        actions: [
          IconButton(
            onPressed: _selectDateRange,
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Chọn khoảng ngày',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _future = _loadReceipts();
          });
          await _future;
        },
        child: FutureBuilder<List<Map<String, dynamic>>>(
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
            final receipts = snapshot.data ?? [];
            if (receipts.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 48),
                  Center(child: Text('Không có hóa đơn.')),
                ],
              );
            }
            final formatter = DateFormat('dd/MM/yyyy HH:mm');
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final receipt = receipts[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.receipt_long),
                    title: Text('Hóa đơn #${receipt['id']}'),
                    subtitle: Text(
                      'Bàn: ${receipt['table_name'] ?? '---'}'
                      'Thanh toán: '
                      '${formatter.format(DateTime.tryParse(receipt['paid_at']?.toString() ?? '') ?? DateTime.now())}',
                    ),
                    trailing: Text(
                      NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
                          .format((receipt['total'] as num?)?.toDouble() ?? 0),
                    ),
                    onTap: () => _openReceipt(receipt['id'] as int? ?? 0),
                  ),
                );
              },
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemCount: receipts.length,
            );
          },
        ),
      ),
    );
  }
}
