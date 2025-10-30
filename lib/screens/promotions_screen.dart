import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/promotion.dart';

/// Admin screen to manage discounts and promotions at runtime.
class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  final List<Promotion> _promotions = [];
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _seedSamplePromotions();
  }

  void _seedSamplePromotions() {
    _promotions.addAll([
      Promotion(
        id: 1,
        name: 'Giảm 10% hóa đơn',
        type: PromotionType.percentage,
        value: 10,
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        endDate: DateTime.now().add(const Duration(days: 14)),
        description: 'Áp dụng cho tất cả món ăn trong tuần lễ vàng.',
        usageLimit: 100,
        usageCount: 48,
      ),
      Promotion(
        id: 2,
        name: 'Tặng 30.000đ',
        type: PromotionType.fixed,
        value: 30000,
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now().add(const Duration(days: 2)),
        description: 'Khuyến mãi cho đơn trên 300.000đ.',
        usageCount: 91,
        usageLimit: 120,
      ),
    ]);
  }

  Future<void> _showPromotionDialog({Promotion? promotion}) async {
    final isEditing = promotion != null;
    final nameController = TextEditingController(text: promotion?.name ?? '');
    final descriptionController =
        TextEditingController(text: promotion?.description ?? '');
    final valueController =
        TextEditingController(text: promotion?.value.toString() ?? '');
    final usageLimitController = TextEditingController(
      text: promotion?.usageLimit != null ? promotion!.usageLimit.toString() : '',
    );
    PromotionType selectedType = promotion?.type ?? PromotionType.percentage;
    DateTime startDate = promotion?.startDate ?? DateTime.now();
    DateTime endDate = promotion?.endDate ?? DateTime.now().add(const Duration(days: 7));
    final formKey = GlobalKey<FormState>();

    final shouldSave = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(isEditing ? 'Cập nhật khuyến mãi' : 'Thêm khuyến mãi'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Tên chương trình'),
                        autofocus: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập tên chương trình';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<PromotionType>(
                        value: selectedType,
                        items: PromotionType.values
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(type.label),
                              ),
                            )
                            .toList(),
                        decoration: const InputDecoration(labelText: 'Loại giảm giá'),
                        onChanged: (value) {
                          if (value != null) {
                            setStateDialog(() => selectedType = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: valueController,
                        decoration: InputDecoration(
                          labelText: selectedType == PromotionType.percentage
                              ? 'Phần trăm (%)'
                              : 'Giá trị (₫)',
                        ),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          final parsed = double.tryParse(value ?? '');
                          if (parsed == null || parsed <= 0) {
                            return 'Giá trị không hợp lệ';
                          }
                          if (selectedType == PromotionType.percentage && parsed > 100) {
                            return 'Phần trăm phải nhỏ hơn hoặc bằng 100';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Mô tả',
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _DatePickerField(
                              label: 'Bắt đầu',
                              date: startDate,
                              onPick: (picked) => setStateDialog(() {
                                if (picked != null) startDate = picked;
                              }),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _DatePickerField(
                              label: 'Kết thúc',
                              date: endDate,
                              onPick: (picked) => setStateDialog(() {
                                if (picked != null) endDate = picked;
                              }),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: usageLimitController,
                        decoration: const InputDecoration(
                          labelText: 'Giới hạn lượt áp dụng',
                          helperText: 'Để trống nếu không giới hạn',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Hủy'),
                ),
                FilledButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    if (endDate.isBefore(startDate)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ngày kết thúc phải sau ngày bắt đầu.')),
                      );
                      return;
                    }
                    Navigator.pop(context, true);
                  },
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldSave == true) {
      final value = double.tryParse(valueController.text.trim()) ?? 0;
      final usageLimit = usageLimitController.text.trim().isEmpty
          ? null
          : int.tryParse(usageLimitController.text.trim());
      setState(() {
        if (isEditing) {
          final index = _promotions.indexWhere((item) => item.id == promotion!.id);
          if (index != -1) {
            _promotions[index] = promotion!.copyWith(
              name: nameController.text.trim(),
              description: descriptionController.text.trim().isEmpty
                  ? null
                  : descriptionController.text.trim(),
              type: selectedType,
              value: value,
              startDate: startDate,
              endDate: endDate,
              usageLimit: usageLimit,
            );
          }
        } else {
          final nextId =
              (_promotions.map((p) => p.id).fold<int>(0, (prev, id) => id > prev ? id : prev)) + 1;
          _promotions.add(
            Promotion(
              id: nextId,
              name: nameController.text.trim(),
              description: descriptionController.text.trim().isEmpty
                  ? null
                  : descriptionController.text.trim(),
              type: selectedType,
              value: value,
              startDate: startDate,
              endDate: endDate,
              usageLimit: usageLimit,
            ),
          );
        }
      });
    }
  }

  void _togglePromotion(Promotion promotion, bool value) {
    final index = _promotions.indexWhere((item) => item.id == promotion.id);
    if (index != -1) {
      setState(() {
        _promotions[index] = promotion.copyWith(active: value);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý khuyến mãi'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPromotionDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Thêm mới'),
      ),
      body: _promotions.isEmpty
          ? const Center(child: Text('Chưa có chương trình khuyến mãi nào.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final promotion = _promotions[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    promotion.name,
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    promotion.description ?? 'Không có mô tả',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              children: [
                                Switch(
                                  value: promotion.active,
                                  onChanged: (value) => _togglePromotion(promotion, value),
                                ),
                                Text(
                                  promotion.active ? 'Đang bật' : 'Đã tắt',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            _InfoChip(
                              icon: Icons.sell_outlined,
                              label: promotion.type == PromotionType.percentage
                                  ? '${promotion.value.toStringAsFixed(0)}%'
                                  : NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
                                      .format(promotion.value),
                            ),
                            _InfoChip(
                              icon: Icons.calendar_today_outlined,
                              label:
                                  '${_dateFormat.format(promotion.startDate)} - ${_dateFormat.format(promotion.endDate)}',
                            ),
                            _InfoChip(
                              icon: Icons.repeat_on_outlined,
                              label: 'Đã dùng: ${promotion.usageCount}${promotion.usageLimit != null ? '/${promotion.usageLimit}' : ''}',
                            ),
                          ],
                        ),
                        if (promotion.endDate.isBefore(DateTime.now())) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Chương trình đã hết hạn',
                            style: TextStyle(color: Theme.of(context).colorScheme.error),
                          ),
                        ],
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => _showPromotionDialog(promotion: promotion),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Chỉnh sửa'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: _promotions.length,
            ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.label,
    required this.date,
    required this.onPick,
  });

  final String label;
  final DateTime date;
  final ValueChanged<DateTime?> onPick;

  @override
  Widget build(BuildContext context) {
    final formatted = DateFormat('dd/MM/yyyy').format(date);
    return OutlinedButton(
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        onPick(picked);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(formatted),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}
