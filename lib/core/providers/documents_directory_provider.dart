import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

final documentsDirectoryProvider = FutureProvider<String>((ref) async {
  final directory = await getApplicationDocumentsDirectory();
  return directory.path;
});
