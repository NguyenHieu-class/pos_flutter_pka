import 'package:flutter/material.dart';

import '../models/category.dart';

/// Chip-like representation of a menu category with optional image.
class CategoryChip extends StatelessWidget {
  const CategoryChip({super.key, required this.category, this.onTap});

  final Category category;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (category.imageUrl != null && category.imageUrl!.isNotEmpty)
              CircleAvatar(
                backgroundImage: NetworkImage(category.imageUrl!),
                radius: 18,
                onBackgroundImageError: (_, __) {},
              )
            else
              CircleAvatar(
                backgroundColor: theme.colorScheme.onPrimaryContainer.withOpacity(0.12),
                radius: 18,
                child: Text(
                  category.name.isNotEmpty
                      ? category.name[0].toUpperCase()
                      : '?',
                ),
              ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: theme.textTheme.titleMedium,
                ),
                if (category.description != null && category.description!.isNotEmpty)
                  Text(
                    category.description!,
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
