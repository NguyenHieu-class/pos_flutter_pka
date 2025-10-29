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

  @override
  void initState() {
    super.initState();
    _future = _kitchenService.fetchKitchenQueue();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _kitchenService.fetchKitchenQueue();
    });
    await _future;
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

  @override
  Widget build(BuildContext context) {
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
                  if (ticket.orderedAt != null) ticket.orderedAt!,
                ];
                return OrderTile(
                  title: ticket.itemName,
                  quantity: ticket.quantity,
                  subtitle: subtitleParts.join(' • '),
                  note: ticket.note,
                  modifiers: ticket.modifiers,
                  trailing: FilledButton.tonal(
                    onPressed: () => _markReady(ticket),
                    child: const Text('Hoàn thành'),
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
