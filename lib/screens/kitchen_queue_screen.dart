import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/kitchen_service.dart';
import '../widgets/order_tile.dart';

/// Standalone screen listing kitchen queue items for quick access.
class KitchenQueueScreen extends StatefulWidget {
  const KitchenQueueScreen({super.key});

  @override
  State<KitchenQueueScreen> createState() => _KitchenQueueScreenState();
}

class _KitchenQueueScreenState extends State<KitchenQueueScreen> {
  final _kitchenService = KitchenService.instance;
  late Future<List<KitchenTicket>> _future;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _future = _kitchenService.fetchKitchenQueue();
    _startAutoRefresh();
  }

  Future<void> _refresh() async {
    final future = _kitchenService.fetchKitchenQueue();
    setState(() {
      _future = future;
    });
    await future;
  }

  Future<void> _markReady(KitchenTicket ticket) async {
    try {
      await _kitchenService.updateItemStatus(
        orderItemId: ticket.orderItemId,
        status: 'ready',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${ticket.itemName} đã sẵn sàng')), 
      );
      await _refresh();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Không thể cập nhật: $error')));
    }
  }

  void _startAutoRefresh() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 8), (_) async {
      if (!mounted) return;
      try {
        final future = _kitchenService.fetchKitchenQueue();
        setState(() {
          _future = future;
        });
        await future;
      } catch (_) {
        // Đã có FutureBuilder hiển thị lỗi nên bỏ qua lỗi làm mới tự động.
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'preparing':
        return 'Đang chế biến';
      case 'ready':
        return 'Đã sẵn sàng';
      case 'served':
        return 'Đã phục vụ';
      case 'cancelled':
        return 'Đã huỷ';
      default:
        return 'Chờ bếp';
    }
  }

  Color _statusColor(String? status, ColorScheme scheme) {
    switch (status) {
      case 'preparing':
        return scheme.primary;
      case 'ready':
        return scheme.tertiary;
      case 'served':
        return scheme.secondary;
      case 'cancelled':
        return scheme.error;
      default:
        return scheme.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Hàng đợi bếp')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<KitchenTicket>>(
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
            final tickets = snapshot.data ?? [];
            if (tickets.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 48),
                  Center(child: Text('Không có món trong hàng đợi.')),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tickets.length,
              itemBuilder: (context, index) {
                final ticket = tickets[index];
                final subtitleParts = [
                  if (ticket.tableLabel != null) ticket.tableLabel!,
                  if (ticket.stationName != null)
                    'Trạm: ${ticket.stationName}',
                  if (ticket.categoryName != null)
                    'Danh mục: ${ticket.categoryName}',
                  if (ticket.orderedAt != null) ticket.orderedAt!,
                  'Trạng thái: ${_statusLabel(ticket.kitchenStatus)}',
                ];
                final notes = <String>[];
                if (ticket.note != null && ticket.note!.isNotEmpty) {
                  notes.add(ticket.note!);
                }
                if (ticket.cancelReason != null &&
                    ticket.cancelReason!.isNotEmpty) {
                  notes.add('Huỷ: ${ticket.cancelReason}');
                }
                return OrderTile(
                  title: ticket.itemName,
                  quantity: ticket.quantity,
                  subtitle: subtitleParts.join(' • '),
                  note: notes.isEmpty ? null : notes.join('\n'),
                  modifiers: ticket.modifiers,
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color:
                              _statusColor(ticket.kitchenStatus, colorScheme)
                                  .withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Text(
                          _statusLabel(ticket.kitchenStatus),
                          style: TextStyle(
                            color: _statusColor(ticket.kitchenStatus, colorScheme),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.tonal(
                        onPressed: ticket.kitchenStatus == 'ready'
                            ? null
                            : () => _markReady(ticket),
                        child: const Text('Hoàn thành'),
                      ),
                    ],
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
