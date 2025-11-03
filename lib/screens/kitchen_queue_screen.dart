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
  bool _autoRefreshEnabled = true;

  static const Duration _autoRefreshInterval = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    _future = _loadQueue();
    if (_autoRefreshEnabled) {
      _startAutoRefresh();
    }
  }

  Future<List<KitchenTicket>> _loadQueue() async {
    final tickets = await _kitchenService.fetchKitchenQueue();
    tickets.sort(_compareTicketsByTimeDesc);
    return tickets;
  }

  Future<void> _refresh() async {
    final future = _loadQueue();
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
    if (!_autoRefreshEnabled) {
      return;
    }
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(_autoRefreshInterval, (_) async {
      if (!mounted || !_autoRefreshEnabled) return;
      try {
        await _refresh();
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

  int _compareTicketsByTimeDesc(KitchenTicket a, KitchenTicket b) {
    final aTime = _ticketDateTime(a);
    final bTime = _ticketDateTime(b);
    if (aTime == null && bTime == null) {
      return b.orderItemId.compareTo(a.orderItemId);
    }
    if (aTime == null) {
      return 1;
    }
    if (bTime == null) {
      return -1;
    }
    return bTime.compareTo(aTime);
  }

  DateTime? _ticketDateTime(KitchenTicket ticket) {
    return _parseTimestamp(ticket.orderedAt) ?? _parseTimestamp(ticket.updatedAt);
  }

  DateTime? _parseTimestamp(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final direct = DateTime.tryParse(value);
    if (direct != null) {
      return direct;
    }
    if (value.contains(' ')) {
      return DateTime.tryParse(value.replaceFirst(' ', 'T'));
    }
    return null;
  }

  void _handleAutoRefreshChanged(bool value) {
    setState(() {
      _autoRefreshEnabled = value;
    });
    if (value) {
      unawaited(_refresh());
      _startAutoRefresh();
    } else {
      _pollingTimer?.cancel();
    }
  }

  Widget _buildAutoRefreshTile() {
    return Card(
      child: SwitchListTile.adaptive(
        title: const Text('Tự động tải lại'),
        subtitle: const Text('Làm mới danh sách sau mỗi 30 giây'),
        value: _autoRefreshEnabled,
        onChanged: _handleAutoRefreshChanged,
      ),
    );
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
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return ListView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _buildAutoRefreshTile(),
                  const SizedBox(height: 24),
                  const Center(child: CircularProgressIndicator()),
                ],
              );
            }
            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _buildAutoRefreshTile(),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Lỗi: ${snapshot.error}'),
                    ),
                  ),
                ],
              );
            }
            final tickets = snapshot.data ?? [];
            if (tickets.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _buildAutoRefreshTile(),
                  const SizedBox(height: 12),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: Text('Không có món trong hàng đợi.')),
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: tickets.length + 1,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildAutoRefreshTile();
                }
                final ticket = tickets[index - 1];
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
