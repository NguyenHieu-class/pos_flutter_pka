import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/table.dart';

class TablesController {
  const TablesController();

  List<PosTable> get tables => const [];
}

final tablesControllerProvider = Provider<TablesController>((ref) {
  return const TablesController();
});
