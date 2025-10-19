import '../../domain/models/table.dart';

abstract class TableRepository {
  const TableRepository();

  Future<List<PosTable>> fetchTables();
  Future<void> updateTable(PosTable table);
}
