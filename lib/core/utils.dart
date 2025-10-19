import 'package:flutter/material.dart';

class AppUtils {
  const AppUtils._();

  static void showNotImplementedSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chức năng đang được phát triển.'),
      ),
    );
  }
}
