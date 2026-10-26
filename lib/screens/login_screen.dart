import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'home_admin_screen.dart';
import 'home_cashier_screen.dart';
import 'home_kitchen_screen.dart';

/// Screen allowing the user to log into the POS system.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController(text: '');
  final _passwordController = TextEditingController(text: '');
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final user = await AuthService.instance
          .login(_usernameController.text.trim(), _passwordController.text);
      if (!mounted) return;
      _goToHome(user);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đăng nhập thất bại: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _goToHome(User user) {
    Widget destination;
    switch (user.role) {
      case 'admin':
        destination = const HomeAdminScreen();
        break;
      case 'kitchen':
        destination = const HomeKitchenScreen();
        break;
      default:
        destination = const HomeCashierScreen();
        break;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF29201B),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/login_restaurant.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              cacheWidth: 1600,
              excludeFromSemantics: true,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Failed to load login background: $error');
                return const ColoredBox(color: Color(0xFF29201B));
              },
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x6629201B), Color(0xB329201B)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Card(
                          color: const Color(0xFFFFFCF8),
                          surfaceTintColor: Colors.transparent,
                          elevation: 12,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Savor POS',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF39281D),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Quản lý nhà hàng, trọn vẹn từng trải nghiệm',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Color(0xFF74675D)),
                                  ),
                                  const SizedBox(height: 24),
                                  TextFormField(
                                    controller: _usernameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Tên đăng nhập',
                                      prefixIcon: Icon(Icons.person_outline),
                                    ),
                                    validator: (value) =>
                                        value == null || value.isEmpty
                                            ? 'Nhập username'
                                            : null,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Mật khẩu',
                                      prefixIcon: Icon(Icons.lock_outline),
                                    ),
                                    validator: (value) =>
                                        value == null || value.isEmpty
                                            ? 'Nhập mật khẩu'
                                            : null,
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton(
                                      onPressed: _isLoading ? null : _submit,
                                      child: _isLoading
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2),
                                            )
                                          : const Text('Đăng nhập'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
