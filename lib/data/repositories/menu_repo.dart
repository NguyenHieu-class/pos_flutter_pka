import '../../domain/models/menu_item.dart';

abstract class MenuRepository {
  const MenuRepository();

  Future<List<MenuItem>> fetchMenuItems();
  Future<void> updateMenuItem(MenuItem item);
}
