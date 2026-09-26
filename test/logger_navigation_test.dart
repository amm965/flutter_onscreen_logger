import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_onscreen_logger/flutter_onscreen_logger.dart';
import 'package:flutter_onscreen_logger/src/extensions/log_item_type_extension.dart';
import 'package:flutter_onscreen_logger/src/logger_overlay/controllers/logger_overlay_controller.dart';
import 'package:flutter_onscreen_logger/src/logger_overlay/views/logger_list_item.dart';
import 'package:get/get.dart';

void main() {
  tearDown(() => Get.reset());

  testWidgets(
    'filters match item colors, and menu icons represent both toggle states',
    (tester) async {
      Get.put(LoggerOverlayController()).isExpanded.value = true;
      await tester.pumpWidget(MaterialApp(home: LoggerOverlayWidget()));
      for (final type in LogItemType.values) {
        final finder = find.widgetWithText(FilterChip, type.name);
        final selected = tester.widget<FilterChip>(finder);
        expect(selected.selectedColor, type.itemColorByType);
        expect(selected.labelStyle?.color, Colors.black);
        expect(selected.showCheckmark, isFalse);
        expect((selected.avatar! as Icon).icon, type.itemIconByType);
        expect((selected.avatar! as Icon).color, Colors.black);
        await tester.ensureVisible(finder);
        await tester.tap(finder);
        await tester.pumpAndSettle();
        final unselected = tester.widget<FilterChip>(finder);
        expect(unselected.selected, isFalse);
        expect(unselected.backgroundColor, Colors.black);
        expect((unselected.avatar! as Icon).color, type.itemColorByType);
        expect(unselected.side?.color, type.itemColorByType);
        expect(unselected.labelStyle?.color, type.itemColorByType);
      }
      await tester.tap(find.byTooltip('Logger options'));
      await tester.pumpAndSettle();
      for (final icon in [
        Icons.pause,
        Icons.sync,
        Icons.share,
        Icons.delete_outline,
      ]) {
        expect(find.byIcon(icon), findsOneWidget);
      }
      await tester.tap(find.text('Pause logging'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Logger options'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      await tester.tap(find.text('Disable auto-scroll'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Logger options'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.sync_disabled), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'jump control counts filtered rows below the viewport and reaches the actual end',
    (tester) async {
      final controller = Get.put(LoggerOverlayController())
        ..isExpanded.value = true
        ..autoScroll.value = false;
      for (var i = 0; i < 30; i++) {
        controller.log(
          LogItem(
            type: LogItemType.info,
            description: List.generate(
              5 + i % 3,
              (line) => 'Entry $i line $line',
            ).join('\n'),
          ),
        );
      }
      await tester.pumpWidget(MaterialApp(home: LoggerOverlayWidget()));
      await tester.pumpAndSettle();
      final row = find.byWidgetPredicate(
        (widget) => widget is LoggerListItem && widget.index == 3,
      );
      await Scrollable.ensureVisible(tester.element(row), alignment: 1);
      await tester.pumpAndSettle();
      expect(
        find.byTooltip('Jump to latest (26 messages below)'),
        findsOneWidget,
      );
      controller.log(LogItem(type: LogItemType.info, description: 'New entry'));
      await tester.pumpAndSettle();
      expect(
        find.byTooltip('Jump to latest (27 messages below)'),
        findsOneWidget,
      );
      controller.toggleType(LogItemType.error);
      controller.log(
        LogItem(type: LogItemType.error, description: 'Filtered out'),
      );
      await tester.pumpAndSettle();
      expect(
        find.byTooltip('Jump to latest (27 messages below)'),
        findsOneWidget,
      );
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(
        controller.listViewScrollController.position.extentAfter,
        lessThanOrEqualTo(1),
      );
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(controller.autoScroll.value, isFalse);
      controller.log(
        LogItem(type: LogItemType.info, description: 'Another new entry'),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FloatingActionButton), findsOneWidget);
      controller.clearAll();
      await tester.pumpAndSettle();
      expect(find.byType(FloatingActionButton), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('scrolling upward suspends following until returning to latest', (
    tester,
  ) async {
    final controller = Get.put(LoggerOverlayController())
      ..isExpanded.value = true;
    await tester.pumpWidget(MaterialApp(home: LoggerOverlayWidget()));
    for (var i = 0; i < 40; i++) {
      OnScreenLog.i(message: 'Entry $i');
    }
    await tester.pumpAndSettle();
    final scroll = controller.listViewScrollController;
    expect(scroll.position.extentAfter, lessThanOrEqualTo(1));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 350));
    await tester.pumpAndSettle();
    final offset = scroll.offset;
    expect(find.byType(FloatingActionButton), findsOneWidget);
    OnScreenLog.i(message: 'Should not interrupt reading');
    await tester.pumpAndSettle();
    expect(scroll.offset, closeTo(offset, 1));
    expect(controller.autoScroll.value, isTrue);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    OnScreenLog.i(message: 'Following again');
    await tester.pumpAndSettle();
    expect(scroll.position.extentAfter, lessThanOrEqualTo(1));
    expect(find.byType(FloatingActionButton), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
