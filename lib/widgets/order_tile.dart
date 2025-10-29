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
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text(quantity.toString()),
        ),
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitle != null && subtitle!.isNotEmpty)
              Text(subtitle!),
            if (modifiers.isNotEmpty)
              Text(
                'Topping: ${modifiers.map((m) => m.name).join(', ')}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (note != null && note!.isNotEmpty)
              Text('Ghi chú: $note', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        trailing: trailing,
      ),
    );
  }
}
