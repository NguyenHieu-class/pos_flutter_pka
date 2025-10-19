import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/settings/app_settings_controller.dart';

class AppSettingsButton extends ConsumerWidget {
  const AppSettingsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Cài đặt',
      icon: const Icon(Icons.settings),
      onPressed: () {
        showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (context) => const _AppSettingsSheet(),
        );
      },
    );
  }
}

class _AppSettingsSheet extends ConsumerWidget {
  const _AppSettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsControllerProvider);
    final controller = ref.read(appSettingsControllerProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cài đặt ứng dụng',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Giữ màn hình sáng ở trang Hoá đơn'),
              subtitle: const Text('Tắt nếu muốn màn hình tự tắt theo cài đặt hệ thống'),
              value: settings.keepScreenAwakeOnBill,
              onChanged: controller.toggleKeepScreenAwakeOnBill,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
