import 'package:flutter/material.dart';
import 'package:flutter_onscreen_logger/flutter_onscreen_logger.dart';
import 'package:flutter_onscreen_logger/src/logger_overlay/controllers/logger_overlay_controller.dart';
import 'package:flutter_onscreen_logger/src/logger_overlay/views/http_log_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  tearDown(() => Get.reset());

  test(
    'network data is snapshotted, formatted, and preserved by the public logger',
    () {
      final data = {
        'name': 'Ada',
        'roles': ['admin', 'reader'],
      };
      final item = LogItem.network(
        type: LogItemType.success,
        details: HttpLogDetails(
          method: 'GET',
          url: 'https://api.example.com/users/1',
          phase: HttpLogPhase.response,
          requestId: 'dio-1',
          statusCode: 200,
          duration: const Duration(milliseconds: 42),
          body: HttpLogDetails.formatBody(data),
        ),
      );
      data['name'] = 'Changed after logging';
      OnScreenLog.log(item);
      final controller = Get.find<LoggerOverlayController>();
      expect(controller.logItems.single, same(item));
      expect(item.description, contains('Request ID: dio-1'));
      expect(item.description, contains('HTTP status: 200'));
      expect(item.description, contains('Elapsed: 42 ms'));
      expect(item.description, contains('  "name": "Ada"'));
      expect(item.description, isNot(contains('Changed after logging')));
      expect(HttpLogDetails.formatBody('{"ok":true}'), '{\n  "ok": true\n}');
      expect(HttpLogDetails.formatBody('plain text'), 'plain text');
      controller.toggleLogging();
      OnScreenLog.log(item);
      expect(controller.logItems, hasLength(1));
    },
  );

  testWidgets(
    'network cards expand to selectable URL and JSON with a copy action at narrow widths',
    (tester) async {
      tester.view.physicalSize = const Size(320, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = Get.put(LoggerOverlayController())
        ..isExpanded.value = true;
      OnScreenLog.log(
        LogItem.network(
          type: LogItemType.success,
          details: HttpLogDetails(
            method: 'POST',
            url: 'https://api.example.com/users/1',
            phase: HttpLogPhase.response,
            requestId: 'dio-1',
            statusCode: 201,
            duration: const Duration(milliseconds: 42),
            body: HttpLogDetails.formatBody({
              'user': {'name': 'Ada', 'active': true},
            }),
          ),
        ),
      );
      await tester.pumpWidget(MaterialApp(home: LoggerOverlayWidget()));
      await tester.pumpAndSettle();
      expect(find.text('POST'), findsOneWidget);
      expect(find.text('HTTP 201'), findsOneWidget);
      expect(find.text('42 ms'), findsOneWidget);
      expect(find.text('/users/1'), findsOneWidget);
      expect(find.text('api.example.com'), findsOneWidget);
      expect(find.text('#dio-1'), findsOneWidget);
      expect(find.text('RESPONSE BODY'), findsNothing);
      await tester.tap(find.text('/users/1'));
      await tester.pumpAndSettle();
      expect(controller.logItemsExpansionState.single, isTrue);
      expect(find.text('RESPONSE BODY'), findsOneWidget);
      expect(find.byType(SelectableText), findsNWidgets(2));
      expect(find.text('Copy log'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'failures without responses show readable details and copy the full log',
    (tester) async {
      var copied = false;
      final item = LogItem.network(
        type: LogItemType.error,
        details: const HttpLogDetails(
          method: 'GET',
          url: 'https://api.example.com/users',
          phase: HttpLogPhase.error,
          requestId: 'http-2',
          error: 'Request failed',
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HttpLogCard(
                item: item,
                index: 0,
                expanded: true,
                onToggle: () {},
                onCopy: () => copied = true,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Failed'), findsOneWidget);
      expect(find.text('FAILURE'), findsOneWidget);
      expect(find.text('Request failed'), findsOneWidget);
      expect(find.text('Body not captured'), findsOneWidget);
      expect(find.textContaining('HTTP null'), findsNothing);
      await tester.tap(find.text('Copy log'));
      expect(copied, isTrue);
    },
  );
  testWidgets(
    'large payloads scroll inside the card without truncating exported data',
    (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final body = HttpLogDetails.formatBody(
        List.generate(300, (i) => {'row': i}),
      );
      final item = LogItem.network(
        type: LogItemType.success,
        details: HttpLogDetails(
          method: 'GET',
          url: 'https://example.com/export',
          phase: HttpLogPhase.response,
          statusCode: 200,
          body: body,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HttpLogCard(
                item: item,
                index: 0,
                expanded: true,
                onToggle: () {},
                onCopy: () {},
              ),
            ),
          ),
        ),
      );
      final panel = find.descendant(
        of: find.byType(HttpLogCard),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is SingleChildScrollView &&
              widget.scrollDirection == Axis.vertical,
        ),
      );
      expect(tester.getSize(panel).height, lessThanOrEqualTo(260));
      expect(find.text('Copy log').hitTestable(), findsOneWidget);
      expect(item.description, contains('"row": 299'));
      await tester.drag(panel, const Offset(0, -180));
      await tester.pumpAndSettle();
      expect(find.text('Copy log').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
