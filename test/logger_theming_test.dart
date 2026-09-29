import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_onscreen_logger/flutter_onscreen_logger.dart';
import 'package:flutter_onscreen_logger/src/logger_overlay/controllers/logger_overlay_controller.dart';
import 'package:get/get.dart';

void main() {
  tearDown(() => Get.reset());

  testWidgets(
    'MaterialApp builder inherits the active theme and follows theme changes',
    (tester) async {
      final controller = _populateLogger();
      final light = _theme(Colors.orange, Brightness.light);
      final dark = _theme(Colors.teal, Brightness.dark);
      final themeMode = ValueNotifier(ThemeMode.light);
      addTearDown(themeMode.dispose);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      final logger = LoggerOverlayWidget();

      await tester.pumpWidget(
        ValueListenableBuilder<ThemeMode>(
          valueListenable: themeMode,
          builder: (context, mode, child) => MaterialApp(
            theme: light,
            darkTheme: dark,
            themeMode: mode,
            home: const Scaffold(),
            builder: (context, child) => _overlayStack(child, logger),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(Get.context, isNull);
      _expectControlsTheme(tester, light);
      await _expectMenuTheme(tester, light);
      expect(controller.isLoggingPaused.value, isTrue);

      themeMode.value = ThemeMode.dark;
      await tester.pumpAndSettle();
      _expectControlsTheme(tester, dark);
      await _expectMenuTheme(tester, dark, label: 'Resume logging');
      expect(controller.isLoggingPaused.value, isFalse);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'GetMaterialApp builder follows Get.changeTheme without a theme override',
    (tester) async {
      _populateLogger();
      final initial = _theme(Colors.orange, Brightness.light);
      final updated = _theme(Colors.green, Brightness.light);
      final logger = LoggerOverlayWidget();

      await tester.pumpWidget(
        GetMaterialApp(
          theme: initial,
          themeMode: ThemeMode.light,
          home: const Scaffold(),
          builder: (context, child) => _overlayStack(child, logger),
        ),
      );
      await tester.pumpAndSettle();
      _expectControlsTheme(tester, initial);

      Get.changeTheme(updated);
      await tester.pumpAndSettle();
      _expectControlsTheme(tester, updated);
      await _expectMenuTheme(tester, updated);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('an explicit theme supports placement outside the host app', (
    tester,
  ) async {
    _populateLogger();
    final overlayTheme = _theme(Colors.red, Brightness.dark);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          fit: StackFit.expand,
          children: [
            MaterialApp(
              theme: _theme(Colors.blue, Brightness.light),
              home: const Scaffold(),
            ),
            LoggerOverlayWidget(theme: overlayTheme),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    _expectControlsTheme(tester, overlayTheme);
    await _expectMenuTheme(tester, overlayTheme);
    await tester.pumpWidget(const SizedBox());
  });
}

LoggerOverlayController _populateLogger() {
  final controller = Get.put(LoggerOverlayController())
    ..isExpanded.value = true
    ..autoScroll.value = false;
  for (var i = 0; i < 30; i++) {
    controller.log(LogItem(type: LogItemType.info, description: 'Entry $i'));
  }
  return controller;
}

ThemeData _theme(Color primaryColor, Brightness brightness) => ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.purple,
    brightness: brightness,
  ),
  primaryColor: primaryColor,
  popupMenuTheme: PopupMenuThemeData(
    color: primaryColor,
    surfaceTintColor: Colors.transparent,
  ),
);

Widget _overlayStack(Widget? child, Widget logger) => Stack(
  fit: StackFit.expand,
  children: [child ?? const SizedBox.shrink(), logger],
);

void _expectControlsTheme(WidgetTester tester, ThemeData expected) {
  expect(expected.primaryColor, isNot(expected.colorScheme.primary));
  final handle = tester.widget<Container>(
    find
        .ancestor(of: find.byIcon(Icons.list), matching: find.byType(Container))
        .first,
  );
  expect(handle.color, expected.primaryColor);
  final jumpFinder = find.byType(FloatingActionButton);
  final jump = tester.widget<FloatingActionButton>(jumpFinder);
  expect(jump.backgroundColor, expected.primaryColor);
  expect(jump.foregroundColor, expected.colorScheme.onPrimary);
  final inherited = Theme.of(tester.element(jumpFinder));
  expect(inherited.brightness, expected.brightness);
  expect(inherited.popupMenuTheme, expected.popupMenuTheme);
}

Future<void> _expectMenuTheme(
  WidgetTester tester,
  ThemeData expected, {
  String label = 'Pause logging',
}) async {
  await tester.tap(find.byTooltip('Logger options'));
  await tester.pumpAndSettle();
  final menuMaterial = tester.widget<Material>(
    find.ancestor(of: find.text(label), matching: find.byType(Material)).first,
  );
  expect(menuMaterial.color, expected.popupMenuTheme.color);
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
  expect(find.text(label), findsNothing);
}
