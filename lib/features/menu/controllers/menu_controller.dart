import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/menu_item.dart';

class MenuController {
  const MenuController();

  List<MenuItem> get items => const [];
}

final menuControllerProvider = Provider<MenuController>((ref) {
  return const MenuController();
});
