import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/kitchen_service.dart';
import '../widgets/order_tile.dart';
import 'login_screen.dart';

class HomeKitchenScreen extends StatefulWidget {
  const HomeKitchenScreen({super.key});

  @override
  State<HomeKitchenScreen> createState() => _HomeKitchenScreenState();
}

class _HomeKitchenScreenState extends State<HomeKitchenScreen> {
  final _kitchenService = KitchenService.instance;
  final Set<int> _updatingTickets = <int>{};

  List<KitchenTicket> _queueTickets = <KitchenTicket>[];
  List<KitchenTicket> _historyTickets = <KitchenTicket>[];

  bool _queueLoading = true;
  bool _historyLoading = true;
  String? _queueError;
  String? _historyError;

  String? _selectedArea;
  String? _selectedTable;
  int? _selectedStation;
  int? _selectedCategory;
  final Set<String> _selectedStatuses = <String>{};

  bool _filtersExpanded = false;

  List<_Option<String>> _areaOptions = <_Option<String>>[];
  List<_Option<String>> _tableOptions = <_Option<String>>[];
  List<_Option<int>> _stationOptions = <_Option<int>>[];
  List<_Option<int>> _categoryOptions = <_Option<int>>[];

  static const Map<String, String> _statusLabels = {
    'queued': 'Chờ bếp',
    'preparing': 'Đang chế biến',
    'ready': 'Hoàn thành',
    'served': 'Đã phục vụ',
    'cancelled': 'Đã huỷ',
  };

  @override
  void initState() {
    super.initState();
    _refreshQueue();
    _refreshHistory();
  }

  Future<void> _refreshQueue() async {
    setState(() {
      _queueLoading = true;
      _queueError = null;
    });
    try {
      final items = await _kitchenService.fetchKitchenQueue(filter: _buildFilter());
      if (!mounted) return;
      setState(() {
        _queueTickets = items;
        _queueLoading = false;
      });
      _recomputeFilterOptions();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _queueError = error.message;
        _queueLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _queueError = 'Không thể tải dữ liệu: $error';
        _queueLoading = false;
      });
    }
  }

  Future<void> _refreshHistory() async {
    setState(() {
      _historyLoading = true;
      _historyError = null;
    });
    try {
      final items = await _kitchenService.fetchKitchenHistory(filter: _buildFilter());
      if (!mounted) return;
      setState(() {
        _historyTickets = items;
        _historyLoading = false;
      });
      _recomputeFilterOptions();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _historyError = error.message;
        _historyLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _historyError = 'Không thể tải dữ liệu: $error';
        _historyLoading = false;
      });
    }
  }

  KitchenFilter _buildFilter() {
    return KitchenFilter(
      areaCode: _selectedArea,
      tableCode: _selectedTable,
      stationId: _selectedStation,
      categoryId: _selectedCategory,
      statuses: Set<String>.from(_selectedStatuses),
    );
  }

  void _onFiltersChanged() {
    _refreshQueue();
    _refreshHistory();
  }

  void _resetFilters() {
    setState(() {
      _selectedArea = null;
      _selectedTable = null;
      _selectedStation = null;
      _selectedCategory = null;
      _selectedStatuses.clear();
    });
    _refreshQueue();
    _refreshHistory();
  }

  void _recomputeFilterOptions() {
    final combined = <KitchenTicket>[..._queueTickets, ..._historyTickets];
    final areaMap = <String, String>{};
    final tableMap = <String, String>{};
    final stationMap = <int, String>{};
    final categoryMap = <int, String>{};

    for (final ticket in combined) {
      final areaCode = ticket.areaCode;
      if (areaCode != null && areaCode.isNotEmpty) {
        final label = (ticket.areaName != null && ticket.areaName!.isNotEmpty)
            ? '$areaCode - ${ticket.areaName}'
            : 'Khu $areaCode';
        areaMap[areaCode] = label;
      }
      final tableCode = ticket.tableCode;
      if (tableCode != null && tableCode.isNotEmpty) {
        final label = (ticket.tableName != null && ticket.tableName!.isNotEmpty)
            ? '$tableCode - ${ticket.tableName}'
            : 'Bàn $tableCode';
        tableMap[tableCode] = label;
      }
      final stationId = ticket.stationId;
      if (stationId != null) {
        final name = ticket.stationName ?? 'Trạm #$stationId';
        stationMap[stationId] = name;
      }
      final categoryId = ticket.categoryId;
      if (categoryId != null) {
        final name = ticket.categoryName ?? 'Danh mục #$categoryId';
        categoryMap[categoryId] = name;
      }
    }

    setState(() {
      _areaOptions = areaMap.entries
          .map((e) => _Option<String>(e.key, e.value))
          .toList()
        ..sort((a, b) => a.label.compareTo(b.label));
      _tableOptions = tableMap.entries
          .map((e) => _Option<String>(e.key, e.value))
          .toList()
        ..sort((a, b) => a.label.compareTo(b.label));
      _stationOptions = stationMap.entries
          .map((e) => _Option<int>(e.key, e.value))
          .toList()
        ..sort((a, b) => a.label.compareTo(b.label));
      _categoryOptions = categoryMap.entries
          .map((e) => _Option<int>(e.key, e.value))
          .toList()
        ..sort((a, b) => a.label.compareTo(b.label));
    });
  }

  Future<void> _logout() async {
    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _handleStatusSelection(
    KitchenTicket ticket,
    String status,
  ) async {
    if (_updatingTickets.contains(ticket.orderItemId)) return;
    if (ticket.kitchenStatus == status) return;

    String? reason;
    if (status == 'cancelled') {
      reason = await _askCancelReason();
      if (reason == null) {
        return;
      }
    }

    await _updateStatus(ticket, status, reason: reason);
  }

  Future<void> _updateStatus(
    KitchenTicket ticket,
    String status, {
    String? reason,
  }) async {
    setState(() {
      _updatingTickets.add(ticket.orderItemId);
    });
    try {
      await _kitchenService.updateItemStatus(
        orderItemId: ticket.orderItemId,
        status: status,
        reason: reason,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã cập nhật ${ticket.itemName} → ${_statusLabel(status)}')),
      );
      await _refreshQueue();
      await _refreshHistory();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Không thể cập nhật: $error')));
    } finally {
      if (!mounted) return;
      setState(() {
        _updatingTickets.remove(ticket.orderItemId);
      });
    }
  }

  Future<String?> _askCancelReason() async {
    final controller = TextEditingController();
    String? errorText;
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Nhập lý do huỷ món'),
              content: TextField(
                controller: controller,
                autofocus: true,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Lý do',
                  errorText: errorText,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Bỏ qua'),
                ),
                FilledButton(
                  onPressed: () {
                    final text = controller.text.trim();
                    if (text.isEmpty) {
                      setState(() {
                        errorText = 'Vui lòng nhập lý do huỷ';
                      });
                      return;
                    }
                    Navigator.of(context).pop(text);
                  },
                  child: const Text('Xác nhận'),
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();
    return result;
  }

  Widget _buildFilters() {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: ExpansionTile(
        title: const Text('Bộ lọc'),
        initiallyExpanded: _filtersExpanded,
        onExpansionChanged: (value) {
          setState(() {
            _filtersExpanded = value;
          });
        },
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Trạng thái', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Tất cả'),
                      selected: _selectedStatuses.isEmpty,
                      onSelected: (_) {
                        setState(() {
                          _selectedStatuses.clear();
                        });
                        _onFiltersChanged();
                      },
                    ),
                    ..._statusLabels.entries.map((entry) {
                      final selected = _selectedStatuses.contains(entry.key);
                      return FilterChip(
                        label: Text(entry.value),
                        selected: selected,
                        onSelected: (value) {
                          setState(() {
                            if (value) {
                              _selectedStatuses.add(entry.key);
                            } else {
                              _selectedStatuses.remove(entry.key);
                            }
                          });
                          _onFiltersChanged();
                        },
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDropdownField<String>(
                  label: 'Khu vực',
                  value: _selectedArea,
                  options: _areaOptions,
                  onChanged: (value) {
                    setState(() {
                      _selectedArea = value;
                    });
                    _onFiltersChanged();
                  },
                ),
                const SizedBox(height: 12),
                _buildDropdownField<String>(
                  label: 'Bàn',
                  value: _selectedTable,
                  options: _tableOptions,
                  onChanged: (value) {
                    setState(() {
                      _selectedTable = value;
                    });
                    _onFiltersChanged();
                  },
                ),
                const SizedBox(height: 12),
                _buildDropdownField<int>(
                  label: 'Trạm bếp',
                  value: _selectedStation,
                  options: _stationOptions,
                  onChanged: (value) {
                    setState(() {
                      _selectedStation = value;
                    });
                    _onFiltersChanged();
                  },
                ),
                const SizedBox(height: 12),
                _buildDropdownField<int>(
                  label: 'Loại đồ ăn',
                  value: _selectedCategory,
                  options: _categoryOptions,
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                    _onFiltersChanged();
                  },
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _resetFilters,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Đặt lại bộ lọc'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketList({
    required List<KitchenTicket> tickets,
    required bool loading,
    required String? error,
    required Future<void> Function() onRefresh,
    required ColorScheme colorScheme,
    required String emptyMessage,
  }) {
    if (loading) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Center(child: CircularProgressIndicator()),
            SizedBox(height: 120),
          ],
        ),
      );
    }
    if (error != null) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              error,
              style: TextStyle(color: colorScheme.error),
            ),
          ],
        ),
      );
    }
    if (tickets.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 48),
            Center(child: Text(emptyMessage)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: tickets.length,
        itemBuilder: (context, index) {
          final ticket = tickets[index];
          final subtitleParts = <String>[];
          if (ticket.tableLabel != null && ticket.tableLabel!.isNotEmpty) {
            subtitleParts.add(ticket.tableLabel!);
          }
          if (ticket.stationName != null && ticket.stationName!.isNotEmpty) {
            subtitleParts.add('Trạm: ${ticket.stationName}');
          }
          if (ticket.categoryName != null && ticket.categoryName!.isNotEmpty) {
            subtitleParts.add('Danh mục: ${ticket.categoryName}');
          }
          if (ticket.orderedAt != null && ticket.orderedAt!.isNotEmpty) {
            subtitleParts.add('Tạo: ${ticket.orderedAt}');
          }
          if (ticket.updatedAt != null && ticket.updatedAt!.isNotEmpty) {
            subtitleParts.add('Cập nhật: ${ticket.updatedAt}');
          }
          subtitleParts.add('Trạng thái: ${_statusLabel(ticket.kitchenStatus)}');

          final notes = <String>[];
          if (ticket.note != null && ticket.note!.isNotEmpty) {
            notes.add(ticket.note!);
          }
          if (ticket.cancelReason != null && ticket.cancelReason!.isNotEmpty) {
            notes.add('Huỷ: ${ticket.cancelReason}');
          }

          return OrderTile(
            title: ticket.itemName,
            quantity: ticket.quantity,
            subtitle: subtitleParts.join(' • '),
            note: notes.isEmpty ? null : notes.join('\n'),
            modifiers: ticket.modifiers,
            trailing: _buildStatusSelector(ticket, colorScheme),
          );
        },
      ),
    );
  }

  Widget _buildStatusSelector(KitchenTicket ticket, ColorScheme colorScheme) {
    final isUpdating = _updatingTickets.contains(ticket.orderItemId);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          decoration: BoxDecoration(
            color: _statusColor(ticket.kitchenStatus, colorScheme).withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Text(
            _statusLabel(ticket.kitchenStatus),
            style: TextStyle(
              color: _statusColor(ticket.kitchenStatus, colorScheme),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _statusLabels.entries.map((entry) {
              final selected = ticket.kitchenStatus == entry.key;
              return ChoiceChip(
                label: Text(entry.value),
                selected: selected,
                selectedColor:
                    _statusColor(entry.key, colorScheme).withOpacity(0.2),
                labelStyle: TextStyle(
                  color: selected
                      ? _statusColor(entry.key, colorScheme)
                      : null,
                ),
                onSelected: isUpdating
                    ? null
                    : (value) {
                        if (!value) return;
                        _handleStatusSelection(ticket, entry.key);
                      },
              );
            }).toList(),
          ),
        ),
        if (isUpdating) ...[
          const SizedBox(height: 8),
          const SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ],
    );
  }

  String _statusLabel(String? status) {
    if (status == null) return _statusLabels['queued']!;
    return _statusLabels[status] ?? status;
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

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<_Option<T>> options,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T?>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        DropdownMenuItem<T?>(
          value: null,
          child: const Text('Tất cả'),
        ),
        ...options.map(
          (option) => DropdownMenuItem<T?>(
            value: option.value,
            child: Text(option.label),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bếp - Quản lý món'),
          actions: [
            IconButton(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              tooltip: 'Đăng xuất',
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Hàng đợi'),
              Tab(text: 'Lịch sử'),
            ],
          ),
        ),
        body: Column(
          children: [
            _buildFilters(),
            Expanded(
              child: TabBarView(
                children: [
                  _buildTicketList(
                    tickets: _queueTickets,
                    loading: _queueLoading,
                    error: _queueError,
                    onRefresh: _refreshQueue,
                    colorScheme: colorScheme,
                    emptyMessage: 'Không có món nào đang chờ.',
                  ),
                  _buildTicketList(
                    tickets: _historyTickets,
                    loading: _historyLoading,
                    error: _historyError,
                    onRefresh: _refreshHistory,
                    colorScheme: colorScheme,
                    emptyMessage: 'Chưa có lịch sử phù hợp với bộ lọc.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Option<T> {
  _Option(this.value, this.label);

  final T value;
  final String label;
}
