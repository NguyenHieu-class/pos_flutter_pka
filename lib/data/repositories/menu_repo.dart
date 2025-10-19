import '../../domain/models/menu_item.dart';

abstract class MenuRepository {
  const MenuRepository();

  Future<List<MenuItem>> listMenu({
    String? query,
    String? category,
    bool? isActive,
  });

  Future<double> getItemPrice(String itemId);
}
