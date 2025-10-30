import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'models/user.dart';
import 'screens/home_admin_screen.dart';
import 'screens/home_cashier_screen.dart';
import 'screens/home_kitchen_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'utils/navigation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi_VN', null);
  Intl.defaultLocale = 'vi_VN';
  await AuthService.instance.loadSavedSession();
  runApp(const POSApp());
}

/// Root widget responsible for bootstrapping authentication state and routing.
class POSApp extends StatefulWidget {
  const POSApp({super.key});

  @override
  State<POSApp> createState() => _POSAppState();
}

class _POSAppState extends State<POSApp> {
  final _authService = AuthService.instance;

  @override
  void initState() {
    super.initState();
    _authService.onSessionExpired = _handleSessionExpired;
  }

  @override
  void dispose() {
    _authService.onSessionExpired = null;
    super.dispose();
  }

  Future<void> _handleSessionExpired() async {
    final navigator = rootNavigatorKey.currentState;
    if (navigator == null) {
      return;
    }
    // Remove every route and show the login screen again.
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
      appBarTheme: const AppBarTheme(centerTitle: true),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );

    return MaterialApp(
      title: 'PKA POS',
      debugShowCheckedModeBanner: false,
      theme: theme,
      navigatorKey: rootNavigatorKey,
      home: ValueListenableBuilder<User?>(
        valueListenable: _authService.currentUser,
        builder: (context, user, _) {
          if (user == null) {
            return const LoginScreen();
          }
          switch (user.role) {
            case 'admin':
              return const HomeAdminScreen();
            case 'kitchen':
              return const HomeKitchenScreen();
            default:
              return const HomeCashierScreen();
          }
        },
      ),
    );
  }
}
