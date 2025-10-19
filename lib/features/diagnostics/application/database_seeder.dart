import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/datasources/mysql_service.dart';

class DatabaseSeeder {
  DatabaseSeeder(this._mysqlService);

  final MysqlService _mysqlService;

  Future<void> runSeed() async {
    final connection = await _mysqlService.getConnection();

    try {
      await connection.transaction((ctx) async {
        await ctx.query('DELETE FROM order_items');
        await ctx.query('DELETE FROM orders');
        await ctx.query('DELETE FROM menu_items');
        await ctx.query('DELETE FROM tables');

        await ctx.query('ALTER TABLE tables AUTO_INCREMENT = 1');
        await ctx.query('ALTER TABLE menu_items AUTO_INCREMENT = 1');
        await ctx.query('ALTER TABLE orders AUTO_INCREMENT = 1');
        await ctx.query('ALTER TABLE order_items AUTO_INCREMENT = 1');

        final tables = List.generate(
          10,
          (index) => ['Bàn ${index + 1}', 'available'],
        );

        for (final table in tables) {
          await ctx.query(
            'INSERT INTO tables (name, status) VALUES (?, ?)',
            table,
          );
        }

        final menuItems = [
          _MenuSeed('Cà phê sữa đá', 'Beverage', 25000),
          _MenuSeed('Cà phê đen nóng', 'Beverage', 22000),
          _MenuSeed('Trà đào cam sả', 'Beverage', 32000),
          _MenuSeed('Sinh tố xoài', 'Beverage', 35000),
          _MenuSeed('Nước ép dưa hấu', 'Beverage', 28000),
          _MenuSeed('Bánh mì thịt', 'Food', 30000),
          _MenuSeed('Bánh mì ốp la', 'Food', 27000),
          _MenuSeed('Xôi mặn', 'Food', 25000),
          _MenuSeed('Mì xào bò', 'Food', 45000),
          _MenuSeed('Phở bò tái', 'Food', 48000),
          _MenuSeed('Khoai tây chiên', 'Snack', 20000),
          _MenuSeed('Gà rán', 'Snack', 40000),
          _MenuSeed('Bánh ngọt phô mai', 'Snack', 36000),
          _MenuSeed('Bánh tart trứng', 'Snack', 24000),
          _MenuSeed('Caramen', 'Snack', 23000),
        ];

        for (final item in menuItems) {
          await ctx.query(
            'INSERT INTO menu_items (name, category, price, is_active) VALUES (?, ?, ?, 1)',
            [item.name, item.category, item.price],
          );
        }
      });
    } catch (error, stackTrace) {
      debugPrint('Database seed failed: $error');
      debugPrint('$stackTrace');
      rethrow;
    }
  }
}

class _MenuSeed {
  const _MenuSeed(this.name, this.category, this.price);

  final String name;
  final String category;
  final num price;
}

final databaseSeederProvider = Provider<DatabaseSeeder>((ref) {
  final mysqlService = ref.read(mysqlServiceProvider);
  return DatabaseSeeder(mysqlService);
});
