import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_onscreen_logger/flutter_onscreen_logger.dart';
import 'package:flutter_onscreen_logger/src/logger_overlay/controllers/logger_overlay_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'SharePlus exports stored entries when filtered and capture is disabled',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'logger-share-test-',
      );
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
      const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(
        pathChannel,
        (_) async => directory.path,
      );
      messenger.setMockMethodCallHandler(shareChannel, (call) async {
        calls.add(call);
        return 'test.share.target';
      });
      final controller = LoggerOverlayController();
      try {
        controller.log(
          LogItem(type: LogItemType.info, description: 'Hidden info'),
        );
        controller.log(
          LogItem(type: LogItemType.error, description: 'Visible error'),
        );
        controller.log(
          LogItem.network(
            type: LogItemType.success,
            details: const HttpLogDetails(
              method: 'GET',
              url: 'https://example.com/posts/1',
              phase: HttpLogPhase.response,
              statusCode: 200,
              requestId: 'dio-42',
              body: '{"title":"Network payload"}',
            ),
          ),
        );
        controller.toggleType(LogItemType.info);
        controller.configure(enabled: false, enabledTypes: {});
        controller.log(
          LogItem(
            type: LogItemType.error,
            description: 'Discarded after disable',
          ),
        );
        await controller.saveAndShareLogItems();
        expect(calls, hasLength(1));
        expect(calls.single.method, 'share');
        final arguments = calls.single.arguments as Map;
        final paths = arguments['paths'] as List;
        expect(paths, hasLength(1));
        final content = await File(paths.single as String).readAsString();
        expect(content, contains('Hidden info'));
        expect(content, contains('Visible error'));
        expect(content, contains('Request ID: dio-42'));
        expect(content, contains('HTTP status: 200'));
        expect(content, contains('Network payload'));
        expect(content, isNot(contains('Discarded after disable')));
        expect(arguments['mimeTypes'], ['text/plain']);
      } finally {
        messenger.setMockMethodCallHandler(pathChannel, null);
        messenger.setMockMethodCallHandler(shareChannel, null);
        controller.onClose();
        await directory.delete(recursive: true);
      }
    },
  );
}
