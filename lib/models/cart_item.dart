import 'menu_item.dart';

class CartItem {
  final MenuItem menuItem;
  int quantity;
  String note;

  CartItem({required this.menuItem, this.quantity = 1, this.note = ''});

  double get totalPrice => menuItem.price * quantity;
}
