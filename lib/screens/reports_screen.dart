import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/order_service.dart';
import '../utils/json_utils.dart';

/// Screen that summarizes receipts into a quick business report.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
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

  Future<List<Map<String, dynamic>>> _loadReceipts() {
    final formatter = DateFormat('yyyy-MM-dd');
    return _orderService.fetchReceipts(
      from: formatter.format(_range.start),
      to: formatter.format(_range.end),
      pageSize: 200,
    );
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _range,
      saveText: 'Áp dụng',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(useMaterial3: true),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked != null) {
      setState(() {
        _range = picked;
        _future = _loadReceipts();
      });
    }
  }

  Map<String, dynamic> _buildSummary(List<Map<String, dynamic>> receipts) {
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    double totalRevenue = 0;
    double totalDiscount = 0;
    final Map<String, double> revenueByDay = {};
    final Map<String, int> receiptsByStaff = {};

    for (final receipt in receipts) {
      final total = parseDouble(receipt['grand_total']) ??
          parseDouble(receipt['total']) ??
          0;
      totalRevenue += total;
      totalDiscount += parseDouble(receipt['discount_total']) ?? 0;

      final date = _parseDate(receipt['created_at'] ?? receipt['date']) ??
          DateTime.now();
      final dayKey = DateFormat('dd/MM').format(date);
      revenueByDay.update(dayKey, (value) => value + total, ifAbsent: () => total);

      final staffName = (receipt['staff_name'] ?? receipt['created_by'] ?? 'Không rõ')
          .toString();
      receiptsByStaff.update(staffName, (value) => value + 1, ifAbsent: () => 1);
    }

    final averageOrder = receipts.isEmpty ? 0 : totalRevenue / receipts.length;

    return {
      'currency': currency,
      'totalRevenue': totalRevenue,
      'totalDiscount': totalDiscount,
      'averageOrder': averageOrder,
      'count': receipts.length,
      'revenueByDay': revenueByDay,
      'receiptsByStaff': receiptsByStaff,
    };
  }

  DateTime? _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        for (final pattern in ['dd/MM/yyyy', 'yyyy-MM-dd HH:mm:ss']) {
          try {
            return DateFormat(pattern).parse(value);
          } catch (_) {
            continue;
          }
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo & thống kê'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _future = _loadReceipts();
              });
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Khoảng thời gian', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        '${DateFormat('dd/MM/yyyy').format(_range.start)} - '
                        '${DateFormat('dd/MM/yyyy').format(_range.end)}',
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: _pickRange,
                  icon: const Icon(Icons.date_range),
                  label: const Text('Chọn ngày'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _ErrorState(
                    message: snapshot.error.toString(),
                    onRetry: () {
                      setState(() {
                        _future = _loadReceipts();
                      });
                    },
                  );
                }
                final receipts = snapshot.data ?? [];
                final summary = _buildSummary(receipts);
                final currency = summary['currency'] as NumberFormat;
                final revenueByDay = summary['revenueByDay'] as Map<String, double>;
                final receiptsByStaff = summary['receiptsByStaff'] as Map<String, int>;

                if (receipts.isEmpty) {
                  return const Center(
                    child: Text('Không có dữ liệu hóa đơn trong khoảng thời gian đã chọn.'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _future = _loadReceipts();
                    });
                    await _future;
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _SummaryCard(
                            title: 'Tổng doanh thu',
                            value: currency.format(summary['totalRevenue'] as double),
                            icon: Icons.payments_outlined,
                            color: Colors.green,
                          ),
                          _SummaryCard(
                            title: 'Số hóa đơn',
                            value: (summary['count'] as int).toString(),
                            icon: Icons.receipt_long_outlined,
                            color: Colors.blue,
                          ),
                          _SummaryCard(
                            title: 'Giảm giá đã áp dụng',
                            value: currency.format(summary['totalDiscount'] as double),
                            icon: Icons.local_offer_outlined,
                            color: Colors.orange,
                          ),
                          _SummaryCard(
                            title: 'Trung bình/đơn',
                            value: currency.format(summary['averageOrder'] as double),
                            icon: Icons.analytics_outlined,
                            color: Colors.purple,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text('Doanh thu theo ngày', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      Card(
                        child: Column(
                          children: revenueByDay.entries
                              .map(
                                (entry) => ListTile(
                                  leading: const Icon(Icons.calendar_today_outlined),
                                  title: Text(entry.key),
                                  trailing: Text(currency.format(entry.value)),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('Hiệu suất nhân viên', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      Card(
                        child: Column(
                          children: receiptsByStaff.entries
                              .map(
                                (entry) => ListTile(
                                  leading: const Icon(Icons.person_outline),
                                  title: Text(entry.key),
                                  trailing: Text('${entry.value} đơn'),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 12),
              Text(title, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              message,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ),
          FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}
