import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrderDraftLine {
  const OrderDraftLine({this.quantity = 1, this.note});

  final int quantity;
  final String? note;

  OrderDraftLine copyWith({int? quantity, Object? note = _unset}) {
    return OrderDraftLine(
      quantity: quantity ?? this.quantity,
      note: note == _unset ? this.note : note as String?,
    );
  }

  static const _unset = Object();
}

class OrderDraftController extends StateNotifier<Map<String, OrderDraftLine>> {
  OrderDraftController() : super(const <String, OrderDraftLine>{});

  OrderDraftLine getDraft(String itemId) {
    return state[itemId] ?? const OrderDraftLine();
  }

  void setQuantity(String itemId, int quantity) {
    if (quantity < 1) {
      quantity = 1;
    }
    final draft = getDraft(itemId).copyWith(quantity: quantity);
    state = <String, OrderDraftLine>{
      ...state,
      itemId: draft,
    };
  }

  void setNote(String itemId, String? note) {
    final normalized = note?.trim();
    final draft = getDraft(itemId).copyWith(
      note: normalized?.isEmpty == true ? null : normalized,
    );
    state = <String, OrderDraftLine>{
      ...state,
      itemId: draft,
    };
  }

  void clear(String itemId) {
    if (!state.containsKey(itemId)) {
      return;
    }
    final next = Map<String, OrderDraftLine>.from(state)..remove(itemId);
    state = next;
  }
}

final orderDraftControllerProvider =
    StateNotifierProvider<OrderDraftController, Map<String, OrderDraftLine>>(
  (ref) {
    return OrderDraftController();
  },
);
