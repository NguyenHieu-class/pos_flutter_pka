import '../../domain/models/table.dart';

abstract class TableRepository {
  const TableRepository();

  Future<List<PosTable>> listTables({TableStatus? status, String? query});
  Future<void> updateStatus(String tableId, TableStatus status);
  Future<int?> getOpenOrderId(String tableId);
  Future<int> openOrder(String tableId);
}
