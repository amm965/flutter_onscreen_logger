import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_onscreen_logger/flutter_onscreen_logger.dart';
import 'package:flutter_onscreen_logger_dio/flutter_onscreen_logger_dio.dart';
// Inspect the session store without mounting an overlay in these integrations.
// ignore: implementation_imports
import 'package:flutter_onscreen_logger/src/logger_overlay/controllers/logger_overlay_controller.dart';
import 'package:get/get.dart' as getx;

class _BodyProbe {
  int formatCalls = 0;

  Object toJson() {
    formatCalls++;
    return {'value': 'payload'};
  }
}

class Adapter implements HttpClientAdapter {
  int status = 200;
  String body = 'hello';
  Map<String, List<String>> headers = {};
  Future<ResponseBody> Function(RequestOptions)? respond;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async =>
      respond?.call(options) ??
      ResponseBody.fromString(body, status, headers: headers);
  @override
  void close({bool force = false}) {}
}

void main() {
  tearDown(() => getx.Get.reset());

  test('default sink obeys capture configuration without an overlay', () async {
    OnScreenLog.init(enabled: false);
    final controller = getx.Get.find<LoggerOverlayController>();
    final adapter = Adapter();
    final dio = Dio()..httpClientAdapter = adapter;
    addTearDown(dio.close);
    dio.interceptors.add(OnScreenLoggerInterceptor());

    expect((await dio.get('https://example.com')).data, 'hello');
    expect(controller.logItems, isEmpty);

    OnScreenLog.configure(enabled: true, enabledTypes: {LogItemType.error});
    expect((await dio.get('https://example.com')).statusCode, 200);
    expect(controller.logItems, isEmpty);
    adapter.status = 503;
    await expectLater(
      dio.get('https://example.com'),
      throwsA(isA<DioException>()),
    );
    expect(controller.logItems.single.type, LogItemType.error);
    expect(controller.logItems.single.httpDetails!.statusCode, 503);

    OnScreenLog.configure(enabledTypes: LogItemType.values.toSet());
    adapter.status = 200;
    expect((await dio.get('https://example.com')).data, 'hello');
    expect(controller.logItems.map((item) => item.type), [
      LogItemType.error,
      LogItemType.info,
      LogItemType.success,
    ]);
  });

  test('disabled and excluded events skip opt-in body formatting', () {
    OnScreenLog.init(enabled: false);
    final controller = getx.Get.find<LoggerOverlayController>();
    final body = _BodyProbe();
    final interceptor = OnScreenLoggerInterceptor(logBodies: true);
    final request = RequestOptions(path: 'https://example.com', data: body);

    interceptor.onRequest(request, RequestInterceptorHandler());
    interceptor.onResponse(
      Response(requestOptions: request, statusCode: 200, data: body),
      ResponseInterceptorHandler(),
    );
    expect(body.formatCalls, 0);
    expect(controller.logItems, isEmpty);

    OnScreenLog.configure(enabled: true, enabledTypes: {LogItemType.error});
    interceptor.onRequest(request, RequestInterceptorHandler());
    interceptor.onResponse(
      Response(requestOptions: request, statusCode: 200, data: body),
      ResponseInterceptorHandler(),
    );
    expect(body.formatCalls, 0);
    expect(controller.logItems, isEmpty);

    interceptor.onResponse(
      Response(requestOptions: request, statusCode: 500, data: body),
      ResponseInterceptorHandler(),
    );
    expect(body.formatCalls, 1);
    expect(controller.logItems.single.type, LogItemType.error);
    expect(controller.logItems.single.httpDetails!.body, contains('payload'));
  });

  test('custom sinks remain active when the core logger is disabled', () async {
    OnScreenLog.init(enabled: false, enabledTypes: {});
    final logs = <LogItem>[];
    final dio = Dio()..httpClientAdapter = Adapter();
    addTearDown(dio.close);
    dio.interceptors.add(
      OnScreenLoggerInterceptor(logBodies: true, log: logs.add),
    );
    expect((await dio.get('https://example.com')).data, 'hello');
    expect(logs.map((item) => item.type), [
      LogItemType.info,
      LogItemType.success,
    ]);
    expect(logs.last.httpDetails!.body, 'hello');
    expect(getx.Get.find<LoggerOverlayController>().logItems, isEmpty);
  });

  test(
    'logs correlated requests and results without changing Dio behavior',
    () async {
      final logs = <LogItem>[];
      final adapter = Adapter();
      final dio = Dio()..httpClientAdapter = adapter;
      dio.interceptors.add(OnScreenLoggerInterceptor(log: logs.add));
      final response = await dio.get(
        'https://user:password@example.com/test?token=secret',
        options: Options(headers: {'authorization': 'private'}),
      );
      expect(response.data, 'hello');
      expect(logs.map((e) => e.type), [LogItemType.info, LogItemType.success]);
      final request = logs.first.httpDetails!;
      final result = logs.last.httpDetails!;
      expect(request.method, 'GET');
      expect(request.url, 'https://example.com/test');
      expect(request.phase, HttpLogPhase.request);
      expect(request.requestId, isNotEmpty);
      expect(request.duration, isNull);
      expect(request.body, isNull);
      expect(result.requestId, request.requestId);
      expect(result.phase, HttpLogPhase.response);
      expect(result.statusCode, 200);
      expect(result.duration, isNotNull);
      expect(result.body, isNull);
      for (final item in logs) {
        final exported = '${item.title}\n${item.description}';
        expect(exported, isNot(contains('secret')));
        expect(exported, isNot(contains('password')));
        expect(exported, isNot(contains('private')));
      }
      adapter.status = 500;
      await expectLater(
        dio.get('https://example.com'),
        throwsA(isA<DioException>()),
      );
      expect(logs.last.type, LogItemType.error);
      final failure = logs.last.httpDetails!;
      expect(failure.phase, HttpLogPhase.error);
      expect(failure.statusCode, 500);
      expect(failure.error, 'badResponse');
      expect(failure.requestId, logs[2].httpDetails!.requestId);
      expect(failure.requestId, isNot(request.requestId));
      dio.close();
    },
  );

  test(
    'opt-in payloads are formatted and request objects stay unchanged',
    () async {
      final logs = <LogItem>[];
      final data = <String, Object>{'name': 'Ada', 'enabled': true};
      final extra = <String, Object>{'custom': 'preserved'};
      final adapter = Adapter()
        ..respond = (request) async {
          expect(request.data, same(data));
          expect(request.extra, extra);
          await Future<void>.delayed(const Duration(milliseconds: 2));
          return ResponseBody.fromString(
            '{"items":[1,2]}',
            201,
            headers: {
              Headers.contentTypeHeader: ['application/json'],
            },
          );
        };
      final dio = Dio()..httpClientAdapter = adapter;
      dio.interceptors.add(
        OnScreenLoggerInterceptor(logBodies: true, log: logs.add),
      );
      final response = await dio.post<dynamic>(
        'https://example.com/items',
        data: data,
        options: Options(extra: extra),
      );
      expect(response.data, {
        'items': [1, 2],
      });
      expect(
        logs.first.httpDetails!.body,
        '{\n  "name": "Ada",\n  "enabled": true\n}',
      );
      expect(
        logs.last.httpDetails!.body,
        '{\n  "items": [\n    1,\n    2\n  ]\n}',
      );
      expect(logs.last.httpDetails!.duration, greaterThan(Duration.zero));
      expect(response.requestOptions.extra, extra);
      dio.close();
    },
  );

  test(
    'captures configured headers and redacts them before storing logs',
    () async {
      OnScreenLog.init(
        networkLogOptions: NetworkLogOptions(
          includeRequestHeaders: true,
          includeResponseHeaders: true,
          includeRequestBody: true,
          includeResponseBody: true,
          redactor: (text) => text.replaceAll('top-secret', '[redacted]'),
        ),
      );
      final adapter = Adapter()
        ..respond = (request) async => ResponseBody.fromString(
          '{"access_token":"top-secret"}',
          200,
          headers: {
            'x-session': ['top-secret'],
          },
        );
      final dio = Dio()..httpClientAdapter = adapter;
      dio.interceptors.add(OnScreenLoggerInterceptor());
      await dio.post<dynamic>(
        'https://example.com',
        data: {'password': 'top-secret'},
        options: Options(headers: {'authorization': 'top-secret'}),
      );

      final items = getx.Get.find<LoggerOverlayController>().logItems;
      expect(items, hasLength(2));
      expect(items.first.httpDetails!.headers, contains('[redacted]'));
      expect(items.last.httpDetails!.headers, contains('[redacted]'));
      expect(items.first.httpDetails!.body, contains('[redacted]'));
      expect(items.last.httpDetails!.body, contains('[redacted]'));
      expect(items.first.description, isNot(contains('top-secret')));
      expect(items.last.description, isNot(contains('top-secret')));
      dio.close();
    },
  );

  test(
    'stream and multipart payloads are omitted without consuming them',
    () async {
      final logs = <LogItem>[];
      var listened = false;
      final stream = Stream<Uint8List>.multi((controller) {
        listened = true;
        controller.add(Uint8List.fromList([1, 2]));
        controller.close();
      });
      final dio = Dio()..httpClientAdapter = Adapter();
      dio.interceptors.add(
        OnScreenLoggerInterceptor(logBodies: true, log: logs.add),
      );
      final response = await dio.post<ResponseBody>(
        'https://example.com/stream',
        data: stream,
        options: Options(responseType: ResponseType.stream),
      );
      expect(listened, isFalse);
      expect(response.data, isA<ResponseBody>());
      expect(
        logs.first.httpDetails!.body,
        '[stream or multipart body omitted]',
      );
      expect(logs.last.httpDetails!.body, '[stream or multipart body omitted]');
      final bytes = await response.data!.stream
          .expand((chunk) => chunk)
          .toList();
      expect(String.fromCharCodes(bytes), 'hello');

      await dio.post<dynamic>(
        'https://example.com/form',
        data: FormData.fromMap({'field': 'value'}),
      );
      expect(logs[2].httpDetails!.body, '[stream or multipart body omitted]');
      dio.close();
    },
  );

  test(
    'concurrent interceptor instances have independent request IDs',
    () async {
      final logs = <LogItem>[];
      final clients = List.generate(2, (_) {
        final dio = Dio()..httpClientAdapter = Adapter();
        dio.interceptors.add(OnScreenLoggerInterceptor(log: logs.add));
        return dio;
      });
      await Future.wait([
        clients[0].get<dynamic>('https://example.com/first'),
        clients[1].get<dynamic>('https://example.com/second'),
      ]);
      final requests = logs
          .where((item) => item.httpDetails!.phase == HttpLogPhase.request)
          .map((item) => item.httpDetails!)
          .toList();
      expect(requests.map((item) => item.requestId).toSet(), hasLength(2));
      for (final request in requests) {
        final response = logs.singleWhere(
          (item) =>
              item.httpDetails!.url == request.url &&
              item.httpDetails!.phase == HttpLogPhase.response,
        );
        expect(response.httpDetails!.requestId, request.requestId);
      }
      for (final dio in clients) {
        dio.close();
      }
    },
  );

  test(
    'unobserved short-circuited requests do not claim elapsed times',
    () async {
      final logs = <LogItem>[];
      final dio = Dio()..httpClientAdapter = Adapter();
      var rejectRequest = false;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (rejectRequest) {
              handler.reject(
                DioException(
                  requestOptions: options,
                  type: DioExceptionType.cancel,
                ),
                true,
              );
            } else {
              handler.resolve(
                Response<dynamic>(
                  requestOptions: options,
                  statusCode: 200,
                  data: 'cached',
                ),
                true,
              );
            }
          },
        ),
      );
      dio.interceptors.add(OnScreenLoggerInterceptor(log: logs.add));

      expect((await dio.get<dynamic>('https://example.com')).data, 'cached');
      rejectRequest = true;
      await expectLater(
        dio.get<dynamic>('https://example.com'),
        throwsA(isA<DioException>()),
      );

      expect(logs.map((item) => item.httpDetails!.phase), [
        HttpLogPhase.response,
        HttpLogPhase.error,
      ]);
      expect(logs.first.httpDetails!.statusCode, 200);
      expect(logs.last.httpDetails!.error, 'cancel');
      for (final item in logs) {
        expect(item.httpDetails!.requestId, isNotEmpty);
        expect(item.httpDetails!.duration, isNull);
        expect(item.description, isNot(contains('Elapsed:')));
      }
      expect(
        logs.first.httpDetails!.requestId,
        isNot(logs.last.httpDetails!.requestId),
      );
      dio.close();
    },
  );

  test('broken log sink cannot block a request', () async {
    final dio = Dio()..httpClientAdapter = Adapter();
    dio.interceptors.add(
      OnScreenLoggerInterceptor(log: (_) => throw StateError('failed')),
    );
    expect((await dio.get('https://example.com')).statusCode, 200);
    dio.close();
  });
}
