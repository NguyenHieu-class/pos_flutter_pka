import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_flutter_pka/app.dart';

void main() {
  testWidgets('App displays bottom navigation destinations', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: POSApp()));

    expect(find.text('Tables'), findsOneWidget);
    expect(find.text('Menu'), findsOneWidget);
    expect(find.text('Bill'), findsOneWidget);
  });
}
