import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppSettings {
  const AppSettings({
    this.keepScreenAwakeOnBill = false,
  });

  final bool keepScreenAwakeOnBill;

  AppSettings copyWith({
    bool? keepScreenAwakeOnBill,
  }) {
    return AppSettings(
      keepScreenAwakeOnBill: keepScreenAwakeOnBill ?? this.keepScreenAwakeOnBill,
    );
  }
}

class AppSettingsController extends StateNotifier<AppSettings> {
  AppSettingsController() : super(const AppSettings());

  void toggleKeepScreenAwakeOnBill(bool value) {
    if (state.keepScreenAwakeOnBill == value) {
      return;
    }
    state = state.copyWith(keepScreenAwakeOnBill: value);
  }
}

final appSettingsControllerProvider =
    StateNotifierProvider<AppSettingsController, AppSettings>((ref) {
  return AppSettingsController();
});
