import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_onscreen_logger/flutter_onscreen_logger.dart';
import 'package:flutter_onscreen_logger/src/logger_overlay/controllers/logger_overlay_controller.dart';
import 'package:get/get.dart';

void main() {
  tearDown(() => Get.reset());

  testWidgets(
    'filters retain stored logs and menu toggles scrolling and clears',
    (tester) async {
      final controller = Get.put(LoggerOverlayController());
      controller.isExpanded.value = true;
      OnScreenLog.i(title: 'Info entry', message: 'one');
      OnScreenLog.e(title: 'Error entry', message: 'two');
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: [
              const MaterialApp(home: Scaffold()),
              LoggerOverlayWidget(),
            ],
          ),
        ),
      );
      await tester.tap(find.widgetWithText(FilterChip, 'info'));
      await tester.pumpAndSettle();
      expect(find.text('Info entry'), findsNothing);
      expect(find.text('Error entry'), findsOneWidget);
      expect(controller.logItems, hasLength(2));
      controller.toggleItemExpansion(1);
      expect(controller.logItemsExpansionState[1], isTrue);
      await tester.tap(find.byTooltip('Logger options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Disable auto-scroll'));
      await tester.pumpAndSettle();
      expect(controller.autoScroll.value, isFalse);
      await tester.tap(find.byTooltip('Logger options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear all'));
      await tester.pumpAndSettle();
      expect(controller.logItems, isEmpty);
      expect(controller.logItemsExpansionState, isEmpty);
      OnScreenLog.e(message: 'new');
      await tester.pumpAndSettle();
      expect(controller.logItemsExpansionState, [false]);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('auto-scroll can pause, resume, and detach safely', (
    tester,
  ) async {
    final controller = Get.put(LoggerOverlayController());
    controller.isExpanded.value = true;
    await tester.pumpWidget(MaterialApp(home: LoggerOverlayWidget()));
    for (var i = 0; i < 30; i++) {
      OnScreenLog.i(message: 'Message $i');
    }
    await tester.pumpAndSettle();
    final scroll = controller.listViewScrollController;
    expect(scroll.offset, greaterThan(0));
    controller.toggleAutoScroll();
    scroll.jumpTo(0);
    OnScreenLog.i(message: 'Paused message');
    await tester.pumpAndSettle();
    expect(scroll.offset, 0);
    controller.toggleAutoScroll();
    await tester.pumpAndSettle();
    expect(scroll.offset, greaterThan(0));
    OnScreenLog.i(message: 'Detach before pending scroll');
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'menu pauses capture and resumes without replaying skipped logs',
    (tester) async {
      final controller = Get.put(LoggerOverlayController());
      controller.isExpanded.value = true;
      OnScreenLog.i(message: 'Before pause');
      await tester.pumpWidget(MaterialApp(home: LoggerOverlayWidget()));
      await tester.tap(find.byTooltip('Logger options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pause logging'));
      await tester.pumpAndSettle();
      expect(controller.isLoggingPaused.value, isTrue);
      expect(controller.autoScroll.value, isTrue);
      controller.toggleItemExpansion(0);
      controller.toggleOverlay();
      await tester.pumpAndSettle();
      OnScreenLog.i(message: 'Skipped info');
      OnScreenLog.e(message: 'Skipped error');
      OnScreenLog.w(message: 'Skipped warning');
      OnScreenLog.s(message: 'Skipped success');
      expect(controller.logItems.map((item) => item.description), [
        'Before pause',
      ]);
      expect(controller.logItemsExpansionState, [true]);
      controller.toggleOverlay();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Logger options'));
      await tester.pumpAndSettle();
      expect(find.text('Resume logging'), findsOneWidget);
      await tester.tap(find.text('Resume logging'));
      OnScreenLog.s(message: 'After resume');
      await tester.pumpAndSettle();
      expect(controller.isLoggingPaused.value, isFalse);
      expect(controller.logItems.map((item) => item.description), [
        'Before pause',
        'After resume',
      ]);
      expect(controller.logItemsExpansionState, [true, false]);
      await tester.pumpWidget(const SizedBox());
    },
  );

  test('multiple types and empty selection preserve source indices', () {
    final controller = LoggerOverlayController();
    for (final type in LogItemType.values) {
      controller.log(LogItem(type: type, description: type.name));
    }
    controller.toggleType(LogItemType.info);
    controller.toggleType(LogItemType.warning);
    expect(controller.visibleIndices, [1, 3]);
    controller.toggleType(LogItemType.success);
    controller.toggleType(LogItemType.error);
    expect(controller.visibleIndices, isEmpty);
    expect(controller.logItems, hasLength(4));
    controller.onClose();
  });
}
