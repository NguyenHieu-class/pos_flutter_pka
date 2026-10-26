import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_flutter_pka/widgets/restaurant_map_view.dart';

void main() {
  test('All 30 map positions have unique codes and stay inside the image', () {
    expect(restaurantMapSpots.map((spots) => spots.length), [9, 11, 10]);
    for (final spots in restaurantMapSpots) {
      expect(spots.map((spot) => spot.code).toSet().length, spots.length);
      for (final spot in spots) {
        expect(spot.x, greaterThanOrEqualTo(0));
        expect(spot.y, greaterThanOrEqualTo(0));
        expect(spot.x + spot.w, lessThanOrEqualTo(1));
        expect(spot.y + spot.h, lessThanOrEqualTo(1));
      }
    }
  });
  testWidgets('User can switch between normal and map views', (tester) async {
    var map = false;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: StatefulBuilder(
      builder: (context, setState) => TableViewToggle(
        map: map,
        onChanged: (value) => setState(() => map = value),
      ),
    ))));
    await tester.tap(find.text('Sơ đồ'));
    await tester.pumpAndSettle();
    expect(map, isTrue);
    await tester.tap(find.text('Thường'));
    await tester.pumpAndSettle();
    expect(map, isFalse);
  });
}
