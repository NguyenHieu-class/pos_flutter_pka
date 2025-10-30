import '../utils/json_utils.dart';
import 'modifier.dart';

/// Describes a modifier group (topping group) with its selection rules.
class ModifierGroup {
  ModifierGroup({
    required this.id,
    required this.name,
    this.minSelect = 0,
    this.maxSelect,
    this.required = false,
    this.sort,
    this.optionCount,
    this.options = const <Modifier>[],
  });

  factory ModifierGroup.fromJson(Map<String, dynamic> json) {
    final minSelectValue = parseInt(json['min_select']) ?? 0;
    final maxSelectValue = parseInt(json['max_select']);
    final requiredRaw = json['required'];
    final optionCountValue = parseInt(json['option_count']);
    final optionsJson = json['options'];
    return ModifierGroup(
      id: parseInt(json['group_id'] ?? json['id']) ?? 0,
      name: json['name'] as String? ?? json['group_name'] as String? ?? '',
      minSelect: minSelectValue < 0 ? 0 : minSelectValue,
      maxSelect: maxSelectValue,
      required: _truthy(requiredRaw),
      sort: parseInt(json['sort']) ?? parseInt(json['group_sort']),
      optionCount: optionCountValue,
      options: optionsJson is List
          ? optionsJson
              .whereType<Map<String, dynamic>>()
              .map(Modifier.fromJson)
              .toList()
          : const <Modifier>[],
    );
  }

  ModifierGroup copyWith({
    List<Modifier>? options,
    int? optionCount,
  }) {
    return ModifierGroup(
      id: id,
      name: name,
      minSelect: minSelect,
      maxSelect: maxSelect,
      required: required,
      sort: sort,
      optionCount: optionCount ?? this.optionCount,
      options: options ?? this.options,
    );
  }

  final int id;
  final String name;
  final int minSelect;
  final int? maxSelect;
  final bool required;
  final int? sort;
  final int? optionCount;
  final List<Modifier> options;
}

bool _truthy(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == '1' || normalized == 'true' || normalized == 'yes';
  }
  return false;
}
