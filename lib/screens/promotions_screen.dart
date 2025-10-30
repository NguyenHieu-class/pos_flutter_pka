import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/promotion.dart';
import '../services/api_service.dart';
import '../services/promotion_service.dart';

/// Admin screen to manage discounts and promotions at runtime.
class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  final PromotionService _promotionService = PromotionService.instance;
  final List<Promotion> _promotions = [];
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  bool _isLoading = false;
  bool _isSaving = false;
  int? _togglingId;
  int? _deletingId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _refreshPromotions(showSnackbarOnError: false);
  }

  Future<void> _refreshPromotions({bool showSnackbarOnError = true}) async {
    setState(() {
      _isLoading = true;
      if (_promotions.isEmpty) {
        _errorMessage = null;
      }
    });
    try {
      final promotions = await _promotionService.fetchPromotions();
      if (!mounted) return;
      setState(() {
        _promotions
          ..clear()
          ..addAll(promotions);
        _errorMessage = null;
      });
    } catch (error) {
      final message = _errorMessageFrom(error);
      if (!mounted) return;
      setState(() {
        _errorMessage = message;
      });
      if (showSnackbarOnError) {
        _showErrorSnackBar(message);
      }
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showPromotionDialog({Promotion? promotion}) async {
    final data = await _openPromotionForm(promotion: promotion);
    if (data == null) return;
    if (promotion == null) {
      await _createPromotion(data);
    } else {
      await _updatePromotion(promotion, data);
    }
  }

  Future<void> _createPromotion(_PromotionFormData data) async {
    setState(() {
      _isSaving = true;
    });
    try {
      final created = await _promotionService.createPromotion(
        name: data.name,
        type: data.type,
        value: data.value,
        code: data.code,
        minSubtotal: data.minSubtotal,
        startDate: data.startDate,
        endDate: data.endDate,
        active: data.active,
      );
      if (!mounted) return;
      setState(() {
        _promotions.insert(0, created);
        _errorMessage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã tạo khuyến mãi thành công.')),
      );
    } catch (error) {
      if (!mounted) return;
      _showErrorSnackBar(_errorMessageFrom(error));
    } finally {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _updatePromotion(
      Promotion original, _PromotionFormData data) async {
    setState(() {
      _isSaving = true;
    });
    try {
      final updated = await _promotionService.updatePromotion(
        id: original.id,
        name: data.name,
        type: data.type,
        value: data.value,
        code: data.code,
        minSubtotal: data.minSubtotal,
        startDate: data.startDate,
        endDate: data.endDate,
        active: data.active,
      );
      if (!mounted) return;
      setState(() {
        final index = _promotions.indexWhere((item) => item.id == original.id);
        if (index != -1) {
          _promotions[index] = updated;
        }
        _errorMessage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật khuyến mãi.')),
      );
    } catch (error) {
      if (!mounted) return;
      _showErrorSnackBar(_errorMessageFrom(error));
    } finally {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _togglePromotion(Promotion promotion, bool value) async {
    setState(() {
      _togglingId = promotion.id;
    });
    try {
      final updated = await _promotionService.updatePromotion(
        id: promotion.id,
        name: promotion.name,
        type: promotion.type,
        value: promotion.value,
        code: promotion.code,
        minSubtotal: promotion.minSubtotal,
        startDate: promotion.startDate,
        endDate: promotion.endDate,
        active: value,
      );
      if (!mounted) return;
      setState(() {
        final index = _promotions.indexWhere((item) => item.id == promotion.id);
        if (index != -1) {
          _promotions[index] = updated;
        }
      });
    } catch (error) {
      if (!mounted) return;
      _showErrorSnackBar(_errorMessageFrom(error));
    } finally {
      if (!mounted) return;
      setState(() {
        _togglingId = null;
      });
    }
  }

  Future<void> _confirmDeletePromotion(Promotion promotion) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa khuyến mãi'),
          content: Text(
            'Bạn có chắc muốn xóa chương trình "${promotion.name}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );
    if (shouldDelete != true) return;

    setState(() {
      _deletingId = promotion.id;
    });
    try {
      await _promotionService.deletePromotion(promotion.id);
      if (!mounted) return;
      setState(() {
        _promotions.removeWhere((item) => item.id == promotion.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa khuyến mãi.')),
      );
    } catch (error) {
      if (!mounted) return;
      _showErrorSnackBar(_errorMessageFrom(error));
    } finally {
      if (!mounted) return;
      setState(() {
        _deletingId = null;
      });
    }
  }

  Future<_PromotionFormData?> _openPromotionForm({Promotion? promotion}) async {
    final messenger = ScaffoldMessenger.of(context);
    return showDialog<_PromotionFormData>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PromotionFormDialog(
        promotion: promotion,
        messenger: messenger,
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _promotions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _promotions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _refreshPromotions(),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_promotions.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshPromotions,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(32),
          children: const [
            SizedBox(height: 120),
            Center(child: Text('Chưa có chương trình khuyến mãi nào.')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshPromotions,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final promotion = _promotions[index];
          final isToggling = _togglingId == promotion.id;
          final isDeleting = _deletingId == promotion.id;
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
                            if ((promotion.code ?? '').isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Mã: ${promotion.code}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      isToggling
                          ? const SizedBox(
                              width: 48,
                              height: 32,
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            )
                          : Column(
                              children: [
                                Switch(
                                  value: promotion.active,
                                  onChanged: _isSaving
                                          ? null
                                          : (value) =>
                                              _togglePromotion(promotion, value),
                                ),
                                Text(
                                  promotion.active ? 'Đang bật' : 'Đã tắt',
                                  style:
                                      Theme.of(context).textTheme.bodySmall,
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
                        label: _formatValueLabel(promotion),
                      ),
                      if (promotion.minSubtotal != null &&
                          promotion.minSubtotal! > 0)
                        _InfoChip(
                          icon: Icons.shopping_bag_outlined,
                          label:
                              'ĐH tối thiểu: ${_currencyFormat.format(promotion.minSubtotal)}',
                        ),
                      if (promotion.startDate != null ||
                          promotion.endDate != null)
                        _InfoChip(
                          icon: Icons.calendar_today_outlined,
                          label: _formatDateRange(promotion),
                        ),
                    ],
                  ),
                  if (promotion.endDate != null &&
                      promotion.endDate!.isBefore(DateTime.now())) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Chương trình đã hết hạn',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: _isSaving
                            ? null
                            : () =>
                                _showPromotionDialog(promotion: promotion),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Chỉnh sửa'),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: (isDeleting || _isSaving)
                            ? null
                            : () => _confirmDeletePromotion(promotion),
                        icon: isDeleting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.delete_outline),
                        label: const Text('Xóa'),
                      ),
                    ],
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

  String _formatValueLabel(Promotion promotion) {
    if (promotion.type == PromotionType.percentage) {
      final value = promotion.value;
      final fraction = value.truncateToDouble() == value ? 0 : 1;
      return '${value.toStringAsFixed(fraction)}%';
    }
    return _currencyFormat.format(promotion.value);
  }

  String _formatDateRange(Promotion promotion) {
    final start = promotion.startDate;
    final end = promotion.endDate;
    if (start != null && end != null) {
      return '${_dateFormat.format(start)} - ${_dateFormat.format(end)}';
    }
    if (start != null) {
      return 'Từ ${_dateFormat.format(start)}';
    }
    if (end != null) {
      return 'Đến ${_dateFormat.format(end)}';
    }
    return 'Không giới hạn';
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _errorMessageFrom(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    return 'Đã xảy ra lỗi, vui lòng thử lại.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý khuyến mãi'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : () => _showPromotionDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Thêm mới'),
      ),
      body: Column(
        children: [
          if (_isLoading || _isSaving)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }
}

class _PromotionFormData {
  const _PromotionFormData({
    required this.name,
    required this.type,
    required this.value,
    required this.active,
    this.code,
    this.minSubtotal,
    this.startDate,
    this.endDate,
  });

  final String? code;
  final String name;
  final PromotionType type;
  final double value;
  final double? minSubtotal;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool active;
}

class _PromotionFormDialog extends StatefulWidget {
  const _PromotionFormDialog({
    required this.promotion,
    required this.messenger,
  });

  final Promotion? promotion;
  final ScaffoldMessengerState messenger;

  @override
  State<_PromotionFormDialog> createState() => _PromotionFormDialogState();
}

class _PromotionFormDialogState extends State<_PromotionFormDialog> {
  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late final TextEditingController _valueController;
  late final TextEditingController _minSubtotalController;
  late final GlobalKey<FormState> _formKey;

  late PromotionType _selectedType;
  late bool _isActive;
  DateTime? _startDate;
  DateTime? _endDate;
  late bool _noTimeLimit;

  @override
  void initState() {
    super.initState();
    final promotion = widget.promotion;
    _formKey = GlobalKey<FormState>();
    _codeController = TextEditingController(text: promotion?.code ?? '');
    _nameController = TextEditingController(text: promotion?.name ?? '');
    _valueController = TextEditingController(
      text: promotion != null ? promotion.value.toString() : '',
    );
    _minSubtotalController = TextEditingController(
      text: promotion != null &&
              promotion.minSubtotal != null &&
              promotion.minSubtotal! > 0
          ? promotion.minSubtotal!.toString()
          : '',
    );
    _selectedType = promotion?.type ?? PromotionType.percentage;
    _isActive = promotion?.active ?? true;
    _startDate = promotion?.startDate;
    _endDate = promotion?.endDate;
    _noTimeLimit = _startDate == null && _endDate == null;
    _ensureDateDefaults();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _valueController.dispose();
    _minSubtotalController.dispose();
    super.dispose();
  }

  void _ensureDateDefaults() {
    if (!_noTimeLimit) {
      _startDate ??= DateUtils.dateOnly(DateTime.now());
      _endDate ??= DateUtils.dateOnly(
        (_startDate ?? DateTime.now()).add(const Duration(days: 7)),
      );
    }
  }

  void _toggleNoTimeLimit(bool value) {
    setState(() {
      _noTimeLimit = value;
      if (value) {
        _startDate = null;
        _endDate = null;
      } else {
        _startDate = DateUtils.dateOnly(DateTime.now());
        _endDate = DateUtils.dateOnly(
          DateTime.now().add(const Duration(days: 7)),
        );
      }
    });
  }

  void _submit() {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }
    if (!_noTimeLimit &&
        _startDate != null &&
        _endDate != null &&
        _endDate!.isBefore(_startDate!)) {
      widget.messenger.showSnackBar(
        const SnackBar(
          content:
              Text('Ngày kết thúc phải sau hoặc bằng ngày bắt đầu.'),
        ),
      );
      return;
    }

    final value = double.tryParse(_valueController.text.trim()) ?? 0;
    final minSubtotalText =
        _minSubtotalController.text.trim().replaceAll(',', '.');
    final minSubtotal = minSubtotalText.isEmpty
        ? null
        : double.tryParse(minSubtotalText);

    if (!mounted) return;
    Navigator.of(context).pop(
      _PromotionFormData(
        code: _codeController.text.trim().isEmpty
            ? null
            : _codeController.text.trim(),
        name: _nameController.text.trim(),
        type: _selectedType,
        value: value,
        minSubtotal: minSubtotal,
        startDate: _noTimeLimit ? null : DateUtils.dateOnly(_startDate!),
        endDate: _noTimeLimit ? null : DateUtils.dateOnly(_endDate!),
        active: _isActive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.promotion == null
            ? 'Thêm khuyến mãi'
            : 'Cập nhật khuyến mãi',
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Mã chương trình (tuỳ chọn)',
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
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
                value: _selectedType,
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
                    setState(() => _selectedType = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _valueController,
                decoration: InputDecoration(
                  labelText: _selectedType == PromotionType.percentage
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
                  if (_selectedType == PromotionType.percentage && parsed > 100) {
                    return 'Phần trăm phải nhỏ hơn hoặc bằng 100';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _minSubtotalController,
                decoration: const InputDecoration(
                  labelText: 'Đơn hàng tối thiểu (₫)',
                  helperText: 'Để trống nếu không giới hạn',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return null;
                  }
                  final normalized = value.replaceAll(',', '.');
                  final parsed = double.tryParse(normalized);
                  if (parsed == null || parsed < 0) {
                    return 'Giá trị không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                value: _noTimeLimit,
                onChanged: _toggleNoTimeLimit,
                contentPadding: EdgeInsets.zero,
                title: const Text('Không giới hạn thời gian'),
              ),
              if (!_noTimeLimit) ...[
                Row(
                  children: [
                    Expanded(
                      child: _DatePickerField(
                        label: 'Bắt đầu',
                        date: _startDate,
                        onPick: (picked) {
                          if (picked != null) {
                            setState(() {
                              _startDate = DateUtils.dateOnly(picked);
                              if (_endDate != null &&
                                  _endDate!.isBefore(_startDate!)) {
                                _endDate = _startDate;
                              }
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DatePickerField(
                        label: 'Kết thúc',
                        date: _endDate,
                        onPick: (picked) {
                          if (picked != null) {
                            setState(() {
                              _endDate = DateUtils.dateOnly(picked);
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              SwitchListTile.adaptive(
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
                title: const Text('Trạng thái'),
                subtitle: Text(_isActive ? 'Đang bật' : 'Đã tắt'),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Lưu'),
        ),
      ],
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
  final DateTime? date;
  final ValueChanged<DateTime?> onPick;

  @override
  Widget build(BuildContext context) {
    final formatted =
        date != null ? DateFormat('dd/MM/yyyy').format(date!) : 'Không đặt';
    return OutlinedButton(
      onPressed: () async {
        final initialDate = date ?? DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: initialDate,
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
