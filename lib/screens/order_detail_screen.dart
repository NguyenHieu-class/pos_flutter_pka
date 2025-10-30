import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/category.dart';
import '../models/item.dart';
import '../models/modifier.dart';
import '../models/modifier_group.dart';
import '../models/order.dart';
import '../services/api_service.dart';
import '../services/order_service.dart';
import '../widgets/item_card.dart';
import '../widgets/order_tile.dart';
import '../utils/json_utils.dart';

/// Screen showing order details and enabling cashiers to add dishes and checkout.
class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId, required this.tableName});

  final int orderId;
  final String tableName;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _PendingOrderItem {
  _PendingOrderItem({
    required this.item,
    required this.quantity,
    required this.modifiers,
    this.note,
  });

  final MenuItem item;
  final int quantity;
  final List<Modifier> modifiers;
  final String? note;

  double get _modifierDelta =>
      modifiers.fold<double>(0, (sum, modifier) => sum + (modifier.price ?? 0));

  double get total => (item.price + _modifierDelta) * quantity;

  List<int> get modifierIds => modifiers.map((modifier) => modifier.id).toList();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _orderService = OrderService.instance;
  late Future<Order> _orderFuture;
  late Future<List<MenuItem>> _menuFuture;
  List<Category> _categories = const [];
  int? _selectedCategoryId;
  final List<_PendingOrderItem> _pendingItems = [];
  bool _sendingItems = false;
  bool _processingCheckout = false;
  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  @override
  void initState() {
    super.initState();
    _orderFuture = _orderService.fetchOrderDetail(widget.orderId);
    _menuFuture = _orderService.fetchItems();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _orderService.fetchCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
      });
    } catch (error) {
      debugPrint('Không thể tải danh mục: $error');
    }
  }

  Future<void> _refreshOrder() async {
    setState(() {
      _orderFuture = _orderService.fetchOrderDetail(widget.orderId);
    });
    await _orderFuture;
  }

  void _selectCategory(int? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _menuFuture = _orderService.fetchItems(categoryId: categoryId);
    });
  }

  Future<void> _addItem(MenuItem item) async {
    try {
      final modifierGroups = await _orderService.fetchItemModifiers(item.id);
      final optionLookup = <int, Modifier>{};
      final selectedModifiers = <int, Set<int>>{};
      for (final group in modifierGroups) {
        final defaults = <int>{};
        for (final option in group.options) {
          optionLookup[option.id] = option;
          if (option.isDefault) {
            defaults.add(option.id);
          }
        }
        selectedModifiers[group.id] = defaults;
      }
      final noteController = TextEditingController();
      int quantity = 1;
      final messenger = ScaffoldMessenger.of(context);
      final confirmed = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 24,
            ),
            child: StatefulBuilder(
              builder: (context, setStateBottomSheet) {
                final selectedOptionIds = selectedModifiers.values
                    .expand((ids) => ids)
                    .toList();
                final modifierDelta = selectedOptionIds
                    .map((id) => optionLookup[id])
                    .whereType<Modifier>()
                    .fold<double>(0, (sum, modifier) => sum + (modifier.price ?? 0));
                final totalPrice = (item.price + modifierDelta) * quantity;
                String? helperForGroup(ModifierGroup group) {
                  final parts = <String>[];
                  final minRequired = group.minSelect > 0
                      ? group.minSelect
                      : (group.required ? 1 : 0);
                  if (minRequired > 0) {
                    parts.add('Tối thiểu $minRequired');
                  } else if (group.required) {
                    parts.add('Bắt buộc');
                  }
                  if (group.maxSelect != null && group.maxSelect! > 0) {
                    parts.add('Tối đa ${group.maxSelect}');
                  }
                  return parts.isEmpty ? null : parts.join(' • ');
                }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          onPressed: quantity > 1
                              ? () => setStateBottomSheet(() {
                                    quantity--;
                                  })
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text('$quantity', style: const TextStyle(fontSize: 18)),
                        IconButton(
                          onPressed: () => setStateBottomSheet(() {
                                quantity++;
                              }),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                        const Spacer(),
                        Text(
                          _currencyFormat.format(totalPrice),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    if (modifierGroups.isNotEmpty) ...[
                      const Divider(),
                      Text('Chọn topping',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ...modifierGroups.map((group) {
                        final selectedIds =
                            selectedModifiers[group.id] ?? <int>{};
                        final hint = helperForGroup(group);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    group.name,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                ),
                                if (hint != null)
                                  Text(
                                    hint,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: group.options.map((option) {
                                final isSelected =
                                    selectedIds.contains(option.id);
                                return FilterChip(
                                  label: Text(
                                    option.price != null && option.price != 0
                                        ? '${option.name} +${_currencyFormat.format(option.price)}'
                                        : option.name,
                                  ),
                                  selected: isSelected,
                                  onSelected: (value) {
                                    setStateBottomSheet(() {
                                      final current =
                                          selectedModifiers.putIfAbsent(
                                              group.id, () => <int>{});
                                      if (value) {
                                        final max = group.maxSelect;
                                        if (max != null && max > 0) {
                                          if (max == 1) {
                                            current
                                              ..clear()
                                              ..add(option.id);
                                          } else if (current.length >= max) {
                                            messenger.showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Chỉ được chọn tối đa $max lựa chọn cho nhóm ${group.name}',
                                                ),
                                              ),
                                            );
                                            return;
                                          } else {
                                            current.add(option.id);
                                          }
                                        } else {
                                          current.add(option.id);
                                        }
                                      } else {
                                        current.remove(option.id);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 12),
                          ],
                        );
                      }),
                    ],
                    const Divider(),
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(labelText: 'Ghi chú'),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          for (final group in modifierGroups) {
                            final selected =
                                selectedModifiers[group.id] ?? <int>{};
                            final minRequired = group.minSelect > 0
                                ? group.minSelect
                                : (group.required ? 1 : 0);
                            if (minRequired > 0 &&
                                selected.length < minRequired) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Vui lòng chọn tối thiểu $minRequired lựa chọn cho nhóm ${group.name}',
                                  ),
                                ),
                              );
                              return;
                            }
                          }
                          Navigator.pop(context, true);
                        },
                        child: const Text('Thêm vào order'),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
          );
        },
      );
      if (confirmed != true) {
        noteController.dispose();
        return;
      }
      final noteText = noteController.text.trim();
      noteController.dispose();
      final chosenModifiers = <Modifier>[];
      for (final group in modifierGroups) {
        final selected = selectedModifiers[group.id];
        if (selected == null || selected.isEmpty) continue;
        for (final option in group.options) {
          if (selected.contains(option.id)) {
            chosenModifiers.add(option);
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _pendingItems.add(
          _PendingOrderItem(
            item: item,
            quantity: quantity,
            modifiers: chosenModifiers,
            note: noteText.isEmpty ? null : noteText,
          ),
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã thêm ${item.name} vào danh sách chờ gửi')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể thêm món: $error')),
      );
    }
  }

  void _removePendingItem(int index) {
    setState(() {
      _pendingItems.removeAt(index);
    });
  }

  Future<void> _sendPendingItems() async {
    if (_pendingItems.isEmpty || _sendingItems) return;
    setState(() {
      _sendingItems = true;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      final itemsToSend = List<_PendingOrderItem>.from(_pendingItems);
      for (final pending in itemsToSend) {
        await _orderService.addItemToOrder(
          orderId: widget.orderId,
          itemId: pending.item.id,
          quantity: pending.quantity,
          modifiers: pending.modifierIds.isEmpty ? null : pending.modifierIds,
          note: pending.note,
        );
      }
      if (!mounted) return;
      final totalQuantity =
          itemsToSend.fold<int>(0, (sum, item) => sum + item.quantity);
      setState(() {
        _pendingItems.clear();
      });
      await _refreshOrder();
      messenger.showSnackBar(
        SnackBar(content: Text('Đã gửi $totalQuantity món tới bếp')),
      );
    } on ApiException catch (error) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } catch (error) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Không thể gửi order: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _sendingItems = false;
        });
      } else {
        _sendingItems = false;
      }
    }
  }

  Future<void> _printReceipt(
    Order order,
    Map<String, dynamic> receipt,
  ) async {
    try {
      final doc = pw.Document();
      final items = order.items;
      final total = parseDouble(receipt['total']) ?? order.total ?? 0;
      final paidAt = receipt['paid_at']?.toString();
      final receiptNo = receipt['receipt_no']?.toString();

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (context) {
            return [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'HÓA ĐƠN THANH TOÁN',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text('Bàn: ${order.tableName ?? widget.tableName}'),
                  if (receiptNo != null && receiptNo.isNotEmpty)
                    pw.Text('Mã hoá đơn: $receiptNo'),
                  if (paidAt != null && paidAt.isNotEmpty)
                    pw.Text('Thanh toán: $paidAt'),
                  pw.SizedBox(height: 16),
                  pw.Table.fromTextArray(
                    headers: ['Món', 'SL', 'Thành tiền'],
                    data: [
                      for (final item in items)
                        [
                          item.name +
                              (item.modifiers.isNotEmpty
                                  ? '\n  + ' +
                                      item.modifiers
                                          .map((m) => m.name)
                                          .join(', ')
                                  : '') +
                              (item.note != null && item.note!.isNotEmpty
                                  ? '\n  Ghi chú: ${item.note}'
                                  : ''),
                          '${item.quantity}',
                          _currencyFormat.format(
                            item.lineTotal ??
                                (item.unitPrice ?? 0) * item.quantity,
                          ),
                        ],
                    ],
                    cellAlignment: pw.Alignment.centerLeft,
                    headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                    ),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(2.4),
                      1: const pw.FlexColumnWidth(0.6),
                      2: const pw.FlexColumnWidth(1),
                    },
                  ),
                  pw.SizedBox(height: 12),
                  pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(
                      'Tổng cộng: ${_currencyFormat.format(total)}',
                      style: pw.TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ];
          },
        ),
      );

      await Printing.layoutPdf(onLayout: (format) async => doc.save());
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể in hóa đơn: $error')),
      );
    }
  }

  Future<void> _showReceiptDialog(
    Order order,
    Map<String, dynamic> receipt,
  ) async {
    final total = parseDouble(receipt['total']) ?? order.total ?? 0;
    final paidMethods = receipt['paid_methods']?.toString();
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Thanh toán thành công'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Bàn: ${order.tableName ?? widget.tableName}'),
                if (receipt['receipt_no'] != null)
                  Text('Mã hoá đơn: ${receipt['receipt_no']}'),
                Text('Tổng tiền: ${_currencyFormat.format(total)}'),
                if (paidMethods != null && paidMethods.isNotEmpty)
                  Text('Thanh toán: $paidMethods'),
                const SizedBox(height: 12),
                Text('Chi tiết món',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                if (order.items.isEmpty)
                  const Text('Không có món nào trong hóa đơn.'),
                ...order.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${item.name} x${item.quantity}'),
                        Text(
                          _currencyFormat.format(
                            item.lineTotal ??
                                (item.unitPrice ?? 0) * item.quantity,
                          ),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (item.modifiers.isNotEmpty)
                          Text(
                            'Topping: ${item.modifiers.map((e) => e.name).join(', ')}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Theme.of(context).hintColor),
                          ),
                        if (item.note != null && item.note!.isNotEmpty)
                          Text(
                            'Ghi chú: ${item.note}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Theme.of(context).hintColor),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => _printReceipt(order, receipt),
              child: const Text('In hoá đơn'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkout(Order order) async {
    if (_pendingItems.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vui lòng gửi hết món chờ trước khi thanh toán.')),
      );
      return;
    }
    if (_processingCheckout) return;
    setState(() {
      _processingCheckout = true;
    });
    try {
      final result = await _orderService.checkoutOrder(widget.orderId);
      if (!mounted) return;
      await _showReceiptDialog(order, result);
      if (!mounted) return;
      Navigator.pop(context);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Không thể thanh toán: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _processingCheckout = false;
        });
      } else {
        _processingCheckout = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    Widget buildMenuSection(bool wideLayout) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 64,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              scrollDirection: Axis.horizontal,
              children: [
                ChoiceChip(
                  label: const Text('Tất cả'),
                  selected: _selectedCategoryId == null,
                  onSelected: (_) => _selectCategory(null),
                ),
                ..._categories.map(
                  (category) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(category.name),
                      selected: _selectedCategoryId == category.id,
                      onSelected: (_) => _selectCategory(category.id),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<MenuItem>>(
              future: _menuFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }
                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return const Center(child: Text('Không có món.'));
                }
                final crossAxisCount = wideLayout ? 3 : 2;
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 4 / 5,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ItemCard(
                      item: item,
                      onTap: () => _addItem(item),
                    );
                  },
                );
              },
            ),
          ),
        ],
      );
    }

    Widget buildOrderSection() {
      return FutureBuilder<Order>(
        future: _orderFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }
          final order = snapshot.data;
          if (order == null) {
            return const Center(child: Text('Không tìm thấy order.'));
          }
          final existingTotal = order.total ?? order.items.fold<double>(
              0,
              (sum, item) =>
                  sum + (item.lineTotal ?? (item.unitPrice ?? 0) * item.quantity));
          final pendingTotal =
              _pendingItems.fold<double>(0, (sum, item) => sum + item.total);
          final pendingCount =
              _pendingItems.fold<int>(0, (sum, item) => sum + item.quantity);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: Text('Bàn ${order.tableName ?? widget.tableName}'),
                subtitle: Text([
                  'Order #${order.id}',
                  'Khách: ${order.customerName ?? '---'}',
                  if (_pendingItems.isNotEmpty) 'Món chờ gửi: $pendingCount',
                ].join(' • ')),
                trailing: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _currencyFormat.format(existingTotal),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (pendingTotal > 0)
                      Text(
                        '+ ${_currencyFormat.format(pendingTotal)} chờ gửi',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Theme.of(context).colorScheme.secondary),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  children: [
                    if (_pendingItems.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text('Món chờ gửi',
                            style: Theme.of(context).textTheme.titleSmall),
                      ),
                      ...List.generate(_pendingItems.length, (index) {
                        final pending = _pendingItems[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text('x${pending.quantity}'),
                            ),
                            title: Text(pending.item.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (pending.modifiers.isNotEmpty)
                                  Text(
                                    'Topping: ${pending.modifiers.map((e) => e.name).join(', ')}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: Theme.of(context).hintColor),
                                  ),
                                if (pending.note != null && pending.note!.isNotEmpty)
                                  Text(
                                    'Ghi chú: ${pending.note}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: Theme.of(context).hintColor),
                                  ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(_currencyFormat.format(pending.total)),
                                IconButton(
                                  tooltip: 'Xoá khỏi danh sách chờ',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _removePendingItem(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const Divider(height: 24),
                    ],
                    if (order.items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: Text('Chưa có món trong order.')),
                      )
                    else ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text('Món đã gửi',
                            style: Theme.of(context).textTheme.titleSmall),
                      ),
                      ...order.items.map(
                        (item) => OrderTile(
                          title: item.name,
                          quantity: item.quantity,
                          note: item.note,
                          modifiers: item.modifiers,
                          subtitle: item.kitchenStatus ?? '',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_pendingItems.isNotEmpty)
                      FilledButton.icon(
                        onPressed: _sendingItems ? null : _sendPendingItems,
                        icon: _sendingItems
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                              )
                            : const Icon(Icons.send),
                        label: Text(_sendingItems ? 'Đang gửi...' : 'Gửi order'),
                      ),
                    if (_pendingItems.isNotEmpty)
                      const SizedBox(height: 12),
                    FilledButton(
                      onPressed: order.items.isEmpty ||
                              _processingCheckout ||
                              _pendingItems.isNotEmpty
                          ? null
                          : () => _checkout(order),
                      child: _processingCheckout
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            )
                          : const Text('Thanh toán & In hoá đơn'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Order bàn ${widget.tableName}')),
      body: isWide
          ? Row(
              children: [
                Expanded(flex: 2, child: buildMenuSection(true)),
                Expanded(child: buildOrderSection()),
              ],
            )
          : Column(
              children: [
                Expanded(child: buildMenuSection(false)),
                Expanded(child: buildOrderSection()),
              ],
            ),
    );
  }
}
