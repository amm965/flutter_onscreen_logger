import 'package:flutter/material.dart';
import 'package:flutter_onscreen_logger/flutter_onscreen_logger.dart';
import 'package:flutter_onscreen_logger/src/logger_overlay/controllers/logger_overlay_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  tearDown(() => Get.reset());

  test('logging without initialization keeps the existing defaults', () {
    OnScreenLog.i(message: 'Before initialization');

    expect(OnScreenLog.isEnabled, isTrue);
    expect(OnScreenLog.isAutoScrollEnabled, isTrue);
    expect(OnScreenLog.enabledTypes, LogItemType.values.toSet());
    for (final type in LogItemType.values) {
      expect(OnScreenLog.isEnabledFor(type), isTrue);
    }
    expect(
      Get.find<LoggerOverlayController>().logItems.single.description,
      'Before initialization',
    );
  });

  test('capture can be disabled and resumed without creating an overlay', () {
    OnScreenLog.init(enabled: false, autoScroll: false);
    final controller = Get.find<LoggerOverlayController>();

    _logEveryType('Skipped');
    OnScreenLog.log(
      LogItem(type: LogItemType.error, description: 'Skipped custom entry'),
    );
    OnScreenLog.log(_networkEntry(LogItemType.success));

    expect(OnScreenLog.isEnabled, isFalse);
    expect(OnScreenLog.isAutoScrollEnabled, isFalse);
    expect(OnScreenLog.isEnabledFor(LogItemType.error), isFalse);
    expect(controller.logItems, isEmpty);
    expect(controller.logItemsExpansionState, isEmpty);
    expect(controller.isExpanded.value, isFalse);

    OnScreenLog.configure(enabled: true);
    OnScreenLog.s(message: 'Captured in the background');

    expect(OnScreenLog.isEnabled, isTrue);
    expect(OnScreenLog.isAutoScrollEnabled, isFalse);
    expect(controller.isExpanded.value, isFalse);
    expect(controller.logItems.map((item) => item.description), [
      'Captured in the background',
    ]);
    expect(controller.logItemsExpansionState, [false]);
  });

  test('capture types apply to convenience, custom, and network entries', () {
    OnScreenLog.init(enabledTypes: {LogItemType.warning, LogItemType.error});
    final controller = Get.find<LoggerOverlayController>();

    _logEveryType('Convenience');
    for (final type in LogItemType.values) {
      OnScreenLog.log(LogItem(type: type, description: 'Custom ${type.name}'));
      OnScreenLog.log(_networkEntry(type));
    }

    expect(controller.logItems, hasLength(6));
    expect(
      controller.logItems.every(
        (item) =>
            item.type == LogItemType.warning || item.type == LogItemType.error,
      ),
      isTrue,
    );
    expect(
      controller.logItems.where((item) => item.httpDetails != null),
      hasLength(2),
    );
    expect(OnScreenLog.isEnabledFor(LogItemType.info), isFalse);
    expect(OnScreenLog.isEnabledFor(LogItemType.warning), isTrue);

    OnScreenLog.configure(enabledTypes: {});
    _logEveryType('Skipped with empty types');
    expect(OnScreenLog.isEnabled, isTrue);
    expect(controller.logItems, hasLength(6));
    for (final type in LogItemType.values) {
      expect(OnScreenLog.isEnabledFor(type), isFalse);
    }

    OnScreenLog.configure(enabledTypes: {LogItemType.success});
    OnScreenLog.s(message: 'Newly enabled success');
    expect(controller.logItems, hasLength(7));
    expect(controller.logItems.last.description, 'Newly enabled success');
  });

  test('capture configuration preserves stored entries and view filters', () {
    OnScreenLog.init();
    OnScreenLog.i(message: 'Stored info');
    OnScreenLog.e(message: 'Stored error');
    final controller = Get.find<LoggerOverlayController>();
    controller.toggleType(LogItemType.info);
    controller.toggleItemExpansion(1);

    OnScreenLog.configure(
      enabled: false,
      enabledTypes: {LogItemType.info},
      autoScroll: false,
    );
    OnScreenLog.i(message: 'Discarded while disabled');

    expect(controller.logItems.map((item) => item.description), [
      'Stored info',
      'Stored error',
    ]);
    expect(controller.logItemsExpansionState, [false, true]);
    expect(controller.visibleIndices, [1]);

    OnScreenLog.configure(enabled: true);
    OnScreenLog.i(message: 'Captured despite view filter');
    OnScreenLog.e(message: 'Discarded by capture filter');

    expect(OnScreenLog.enabledTypes, {LogItemType.info});
    expect(OnScreenLog.isAutoScrollEnabled, isFalse);
    expect(controller.logItems, hasLength(3));
    expect(controller.visibleIndices, [1]);
    expect(controller.logItemsExpansionState, [false, true, false]);

    OnScreenLog.init();

    expect(OnScreenLog.isEnabled, isTrue);
    expect(OnScreenLog.isAutoScrollEnabled, isTrue);
    expect(OnScreenLog.enabledTypes, LogItemType.values.toSet());
    expect(controller.logItems, hasLength(3));
    expect(controller.visibleIndices, [1]);
    expect(controller.logItemsExpansionState, [false, true, false]);
  });

  test('caller-owned sets and returned snapshots cannot mutate capture', () {
    final initialTypes = {LogItemType.error};
    OnScreenLog.init(enabledTypes: initialTypes);
    initialTypes.add(LogItemType.info);

    expect(OnScreenLog.enabledTypes, {LogItemType.error});
    final originalSnapshot = OnScreenLog.enabledTypes;
    expect(
      () => originalSnapshot.add(LogItemType.warning),
      throwsUnsupportedError,
    );

    final updatedTypes = {LogItemType.success};
    OnScreenLog.configure(enabledTypes: updatedTypes);
    updatedTypes.clear();

    expect(originalSnapshot, {LogItemType.error});
    expect(OnScreenLog.enabledTypes, {LogItemType.success});
    expect(() => OnScreenLog.enabledTypes.clear(), throwsUnsupportedError);
    _logEveryType('Snapshot');
    expect(
      Get.find<LoggerOverlayController>().logItems.single.type,
      LogItemType.success,
    );
  });

  testWidgets('menu and public settings stay synchronized across remounts', (
    tester,
  ) async {
    OnScreenLog.init(
      enabled: false,
      enabledTypes: {LogItemType.error},
      autoScroll: false,
    );
    final controller = Get.find<LoggerOverlayController>();
    controller.isExpanded.value = true;
    await tester.pumpWidget(MaterialApp(home: LoggerOverlayWidget()));

    await _openMenu(tester);
    expect(find.text('Resume logging'), findsOneWidget);
    expect(find.text('Enable auto-scroll'), findsOneWidget);
    await tester.tap(find.text('Resume logging'));
    await tester.pumpAndSettle();
    expect(OnScreenLog.isEnabled, isTrue);
    expect(OnScreenLog.enabledTypes, {LogItemType.error});

    await _openMenu(tester);
    await tester.tap(find.text('Enable auto-scroll'));
    await tester.pumpAndSettle();
    expect(OnScreenLog.isAutoScrollEnabled, isTrue);

    OnScreenLog.configure(enabled: false, autoScroll: false);
    await _openMenu(tester);
    expect(find.text('Resume logging'), findsOneWidget);
    expect(find.text('Enable auto-scroll'), findsOneWidget);
    await tester.tap(find.text('Resume logging'));
    await tester.pumpAndSettle();
    OnScreenLog.e(message: 'Survives remount');
    OnScreenLog.configure(enabled: false);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await tester.pumpWidget(MaterialApp(home: LoggerOverlayWidget()));
    await tester.pumpAndSettle();

    expect(OnScreenLog.isEnabled, isFalse);
    expect(OnScreenLog.isAutoScrollEnabled, isFalse);
    expect(OnScreenLog.enabledTypes, {LogItemType.error});
    expect(controller.logItems.single.description, 'Survives remount');
    await _openMenu(tester);
    expect(find.text('Resume logging'), findsOneWidget);
    expect(find.text('Enable auto-scroll'), findsOneWidget);
    await tester.tap(find.text('Resume logging'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('programmatic auto-scroll changes apply to the attached list', (
    tester,
  ) async {
    OnScreenLog.init(autoScroll: false);
    final controller = Get.find<LoggerOverlayController>();
    controller.isExpanded.value = true;
    await tester.pumpWidget(MaterialApp(home: LoggerOverlayWidget()));
    for (var i = 0; i < 30; i++) {
      OnScreenLog.i(message: 'Entry $i');
    }
    await tester.pumpAndSettle();
    expect(controller.listViewScrollController.offset, 0);

    OnScreenLog.configure(autoScroll: true);
    await tester.pumpAndSettle();
    expect(controller.listViewScrollController.offset, greaterThan(0));

    OnScreenLog.configure(autoScroll: false);
    controller.listViewScrollController.jumpTo(0);
    OnScreenLog.i(message: 'Stored without scrolling');
    await tester.pumpAndSettle();
    expect(controller.listViewScrollController.offset, 0);
    expect(controller.logItems.last.description, 'Stored without scrolling');
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('automatic errors obey capture at occurrence and delivery', (
    tester,
  ) async {
    final originalErrorHandler = FlutterError.onError;
    final originalErrorWidgetBuilder = ErrorWidget.builder;
    late final void Function(FlutterErrorDetails) loggerErrorHandler;
    try {
      OnScreenLog.onError();
      loggerErrorHandler = FlutterError.onError!;
    } finally {
      FlutterError.onError = originalErrorHandler;
      ErrorWidget.builder = originalErrorWidgetBuilder;
    }
    void reportError(String message) => loggerErrorHandler(
      FlutterErrorDetails(
        exception: StateError(message),
        stack: StackTrace.current,
      ),
    );

    OnScreenLog.init(enabled: false);
    final controller = Get.find<LoggerOverlayController>();
    reportError('Occurred while disabled');
    OnScreenLog.configure(enabled: true);
    await tester.pump(const Duration(milliseconds: 101));
    expect(controller.logItems, isEmpty);

    OnScreenLog.configure(enabledTypes: {LogItemType.info});
    reportError('Occurred while error capture was excluded');
    OnScreenLog.configure(enabledTypes: {LogItemType.error});
    await tester.pump(const Duration(milliseconds: 101));
    expect(controller.logItems, isEmpty);

    reportError('Pending when capture was disabled');
    OnScreenLog.configure(enabled: false);
    await tester.pump(const Duration(milliseconds: 101));
    expect(controller.logItems, isEmpty);

    OnScreenLog.configure(enabled: true);
    reportError('Captured error');
    await tester.pump(const Duration(milliseconds: 101));
    expect(controller.logItems.single.title, contains('Captured error'));
    expect(controller.logItems.single.type, LogItemType.error);
  });
}

void _logEveryType(String prefix) {
  OnScreenLog.i(message: '$prefix info');
  OnScreenLog.w(message: '$prefix warning');
  OnScreenLog.e(message: '$prefix error');
  OnScreenLog.s(message: '$prefix success');
}

LogItem _networkEntry(LogItemType type) => LogItem.network(
  type: type,
  details: const HttpLogDetails(
    method: 'GET',
    url: 'https://example.com/items',
    phase: HttpLogPhase.response,
    statusCode: 200,
  ),
);

Future<void> _openMenu(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Logger options'));
  await tester.pumpAndSettle();
}
