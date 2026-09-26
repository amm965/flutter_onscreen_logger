import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_onscreen_logger/flutter_onscreen_logger.dart';
import 'package:flutter_onscreen_logger_http/flutter_onscreen_logger_http.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
// Inspect the session store without mounting an overlay in these integrations.
// ignore: implementation_imports
import 'package:flutter_onscreen_logger/src/logger_overlay/controllers/logger_overlay_controller.dart';
import 'package:get/get.dart';

void main() {
  tearDown(() => Get.reset());

  test('default sink obeys capture configuration without an overlay', () async {
    OnScreenLog.init(enabled: false);
    final controller = Get.find<LoggerOverlayController>();
    var status = 200;
    final client = OnScreenLoggerClient(
      MockClient((_) async => http.Response('response', status)),
    );
    addTearDown(client.close);
    final url = Uri.parse('https://example.com');

    expect((await client.get(url)).body, 'response');
    expect(controller.logItems, isEmpty);

    OnScreenLog.configure(enabled: true, enabledTypes: {LogItemType.error});
    expect((await client.get(url)).statusCode, 200);
    expect(controller.logItems, isEmpty);
    status = 503;
    expect((await client.get(url)).statusCode, 503);
    expect(controller.logItems.single.type, LogItemType.error);
    expect(controller.logItems.single.httpDetails!.statusCode, 503);

    OnScreenLog.configure(enabledTypes: LogItemType.values.toSet());
    status = 200;
    expect((await client.get(url)).body, 'response');
    expect(controller.logItems.map((item) => item.type), [
      LogItemType.error,
      LogItemType.info,
      LogItemType.success,
    ]);
  });

  test('custom sinks remain active when the core logger is disabled', () async {
    OnScreenLog.init(enabled: false, enabledTypes: {});
    final logs = <LogItem>[];
    final client = OnScreenLoggerClient(
      MockClient((_) async => http.Response('response', 200)),
      log: logs.add,
    );
    addTearDown(client.close);
    expect(
      (await client.get(Uri.parse('https://example.com'))).body,
      'response',
    );
    expect(logs.map((item) => item.type), [
      LogItemType.info,
      LogItemType.success,
    ]);
    expect(Get.find<LoggerOverlayController>().logItems, isEmpty);
  });

  test('logs requests and HTTP errors, preserves body and metadata', () async {
    final logs = <LogItem>[];
    final client = OnScreenLoggerClient(
      MockClient((request) async {
        expect(request.body, 'payload');
        return http.Response('response', 503, headers: {'x-test': 'yes'});
      }),
      log: logs.add,
    );
    final response = await client.post(
      Uri.parse('https://user:password@example.com/a?token=secret'),
      body: 'payload',
      headers: {'authorization': 'private'},
    );
    expect(response.body, 'response');
    expect(response.headers['x-test'], 'yes');
    expect(logs.map((e) => e.type), [LogItemType.info, LogItemType.error]);
    final request = logs.first.httpDetails!;
    final result = logs.last.httpDetails!;
    expect(request.phase, HttpLogPhase.request);
    expect(request.method, 'POST');
    expect(request.url, 'https://example.com/a');
    expect(request.requestId, isNotEmpty);
    expect(request.duration, isNull);
    expect(result.requestId, request.requestId);
    expect(result.phase, HttpLogPhase.response);
    expect(result.statusCode, 503);
    expect(result.duration, isNotNull);
    expect(request.body, isNull);
    expect(result.body, isNull);
    for (final item in logs) {
      final exported = '${item.title}\n${item.description}';
      expect(exported, isNot(contains('secret')));
      expect(exported, isNot(contains('password')));
      expect(exported, isNot(contains('private')));
    }
    client.close();
  });

  test(
    'concurrent clients correlate results and time receipt of headers',
    () async {
      final logs = <LogItem>[];
      final firstResponse = Completer<http.StreamedResponse>();
      final secondResponse = Completer<http.StreamedResponse>();
      final first = OnScreenLoggerClient(
        MockClient.streaming((_, _) => firstResponse.future),
        log: logs.add,
      );
      final second = OnScreenLoggerClient(
        MockClient.streaming((_, _) => secondResponse.future),
        log: logs.add,
      );
      final pendingFirst = first.send(
        http.Request('GET', Uri.parse('https://example.com/first')),
      );
      final pendingSecond = second.send(
        http.Request('GET', Uri.parse('https://example.com/second')),
      );
      expect(logs, hasLength(2));
      expect(
        logs[0].httpDetails!.requestId,
        isNot(logs[1].httpDetails!.requestId),
      );
      await Future<void>.delayed(const Duration(milliseconds: 2));
      secondResponse.complete(http.StreamedResponse(const Stream.empty(), 202));
      await pendingSecond;
      expect(logs.last.httpDetails!.requestId, logs[1].httpDetails!.requestId);
      expect(logs.last.httpDetails!.statusCode, 202);
      expect(logs.last.httpDetails!.duration, greaterThan(Duration.zero));
      firstResponse.complete(http.StreamedResponse(const Stream.empty(), 200));
      await pendingFirst;
      expect(logs.last.httpDetails!.requestId, logs[0].httpDetails!.requestId);
      first.close();
      second.close();
    },
  );

  test(
    'transport failures log a safe category and preserve the error',
    () async {
      final logs = <LogItem>[];
      final error = http.ClientException(
        'offline https://example.com?token=secret',
      );
      final client = OnScreenLoggerClient(
        MockClient((_) async => throw error),
        log: logs.add,
      );
      await expectLater(
        client.get(Uri.parse('https://example.com')),
        throwsA(same(error)),
      );
      expect(logs.last.httpDetails!.phase, HttpLogPhase.error);
      expect(
        logs.last.httpDetails!.requestId,
        logs.first.httpDetails!.requestId,
      );
      expect(logs.last.httpDetails!.duration, isNotNull);
      expect(logs.last.httpDetails!.error, 'Request failed');
      expect(logs.last.description, isNot(contains('secret')));
      client.close();
    },
  );

  test('transport failures propagate even if logging fails', () async {
    final error = http.ClientException('offline');
    final client = OnScreenLoggerClient(
      MockClient((_) async => throw error),
      log: (_) => throw StateError('sink failed'),
    );
    await expectLater(
      client.get(Uri.parse('https://example.com')),
      throwsA(same(error)),
    );
    client.close();
  });

  test('response stream errors propagate and are logged', () async {
    final logs = <LogItem>[];
    final error = StateError('stream failed https://example.com?token=secret');
    var listened = false;
    final chunks = Stream<List<int>>.multi((controller) {
      listened = true;
      controller.add([1, 2, 3]);
      controller.addError(error);
      controller.close();
    });
    final client = OnScreenLoggerClient(
      MockClient.streaming((_, _) async => http.StreamedResponse(chunks, 200)),
      log: logs.add,
    );
    final response = await client.send(
      http.Request('GET', Uri.parse('https://example.com')),
    );
    expect(listened, isFalse);
    expect(logs, hasLength(2));
    final headerDuration = logs.last.httpDetails!.duration;
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await expectLater(
      response.stream,
      emitsInOrder([
        [1, 2, 3],
        emitsError(same(error)),
        emitsDone,
      ]),
    );
    expect(logs.last.type, LogItemType.error);
    expect(logs.last.httpDetails!.phase, HttpLogPhase.error);
    expect(logs.last.httpDetails!.requestId, logs.first.httpDetails!.requestId);
    expect(logs.last.httpDetails!.statusCode, 200);
    expect(logs.last.httpDetails!.duration, headerDuration);
    expect(logs.last.httpDetails!.error, 'Response stream failed');
    expect(logs.last.description, isNot(contains('secret')));
    client.close();
  });
}
