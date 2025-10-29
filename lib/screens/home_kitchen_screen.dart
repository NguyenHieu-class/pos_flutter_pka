import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/kitchen_service.dart';
import '../widgets/order_tile.dart';
import 'login_screen.dart';

/// Home screen dedicated to kitchen staff displaying queue of items to prepare.
class HomeKitchenScreen extends StatefulWidget {
  const HomeKitchenScreen({super.key});

  @override
  State<HomeKitchenScreen> createState() => _HomeKitchenScreenState();
}

class _HomeKitchenScreenState extends State<HomeKitchenScreen> {
  final _kitchenService = KitchenService.instance;
  late Future<List<KitchenTicket>> _ticketsFuture;

  @override
  void initState() {
    super.initState();
    _ticketsFuture = _loadQueue();
  }

  Future<List<KitchenTicket>> _loadQueue() {
    return _kitchenService.fetchKitchenQueue();
  }

  void _logout() async {
    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _updateStatus(KitchenTicket ticket, String status) async {
    try {
      await _kitchenService.updateItemStatus(
        orderItemId: ticket.orderItemId,
        status: status,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã cập nhật trạng thái cho ${ticket.itemName}')), 
      );
      setState(() {
        _ticketsFuture = _loadQueue();
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể cập nhật: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bếp - Hàng đợi chế biến'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _ticketsFuture = _loadQueue();
          });
          await _ticketsFuture;
        },
        child: FutureBuilder<List<KitchenTicket>>(
          future: _ticketsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(snapshot.error.toString()),
                  ),
                ],
              );
            }
            final tickets = snapshot.data ?? [];
            if (tickets.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 48),
                  Center(child: Text('Không có món nào đang chờ.')),
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
                  if (ticket.kitchenStatus != null)
                    'Trạng thái: ${ticket.kitchenStatus}',
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
                  trailing: PopupMenuButton<String>(
                    onSelected: (status) => _updateStatus(ticket, status),
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'preparing', child: Text('Đang làm')),
                      PopupMenuItem(value: 'ready', child: Text('Hoàn thành')),
                    ],
                    child: const Icon(Icons.more_vert),
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
