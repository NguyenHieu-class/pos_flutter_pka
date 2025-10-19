import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controllers/cart_controller.dart';
import 'controllers/category_controller.dart';
import 'controllers/menu_controller.dart';
import 'screens/order_screen.dart';
import 'services/database_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final databaseService = DatabaseService();
  await databaseService.init();
  Get.put<DatabaseService>(databaseService, permanent: true);
  runApp(const MyApp());
}

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<MenuController>(MenuController(), permanent: true);
    Get.put<CategoryController>(CategoryController(), permanent: true);
    Get.put<CartController>(CartController(), permanent: true);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Restaurant POS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey.shade100,
      ),
      initialBinding: AppBinding(),
      home: const OrderScreen(),
    );
  }
}
