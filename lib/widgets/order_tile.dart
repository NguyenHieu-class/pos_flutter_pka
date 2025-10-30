import 'package:flutter/material.dart';

import '../models/modifier.dart';

/// List tile summarizing an order line item with modifiers and note.
class OrderTile extends StatelessWidget {
  const OrderTile({
    super.key,
    required this.title,
    required this.quantity,
    this.subtitle,
    this.note,
    this.modifiers = const <Modifier>[],
    this.trailing,
  });

  final String title;
  final int quantity;
  final String? subtitle;
  final String? note;
  final List<Modifier> modifiers;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final children = <Widget>[];

    if (subtitle != null && subtitle!.isNotEmpty) {
      children.add(Text(subtitle!));
    }
    if (modifiers.isNotEmpty) {
      children.add(
        Text(
          'Topping: ${modifiers.map((m) => m.name).join(', ')}',
          style: theme.textTheme.bodySmall,
        ),
      );
    }
    if (note != null && note!.isNotEmpty) {
      children.add(
        Text(
          'Ghi chú: $note',
          style: theme.textTheme.bodySmall,
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              child: Text(quantity.toString()),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  if (children.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    ...List.generate(children.length, (index) {
                      final widget = children[index];
                      final isLast = index == children.length - 1;
                      return Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 0 : 2),
                        child: widget,
                      );
                    }),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 12),
              Flexible(
                fit: FlexFit.loose,
                child: Align(
                  alignment: Alignment.topRight,
                  child: trailing!,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
