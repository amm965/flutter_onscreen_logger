import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:example/main.dart';

void main() {
  testWidgets('example generates logs and opens logger options', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Generate Test Log Messages'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 800));
    }
    await tester.tap(find.byIcon(Icons.list));
    await tester.pumpAndSettle();
    expect(find.text('OnScreen Logger'), findsOneWidget);
    expect(find.byType(FilterChip), findsNWidgets(4));
    await tester.tap(find.byTooltip('Logger options'));
    await tester.pumpAndSettle();
    expect(find.text('Share all'), findsOneWidget);
    expect(find.text('Clear all'), findsOneWidget);
  });
}
