import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:example/main.dart';
import 'package:example/network_demos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_onscreen_logger/flutter_onscreen_logger.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _DemoAdapter implements HttpClientAdapter {
  final paths = <String>[];
  bool closed = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    paths.add(options.uri.path);
    return ResponseBody.fromString(
      '{"id":1}',
      options.uri.path.endsWith('/0') ? 404 : 200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) => closed = true;
}

void main() {
  tearDown(OnScreenLog.clearAll);

  for (final isDio in [true, false]) {
    testWidgets(
      '${isDio ? 'Dio' : 'HTTP'} button uses its connector for success and error requests',
      (tester) async {
        final adapter = _DemoAdapter();
        final httpPaths = <String>[];
        final clients = DemoNetworkClients(
          dio: Dio()..httpClientAdapter = adapter,
          httpClient: MockClient((request) async {
            httpPaths.add(request.url.path);
            return http.Response(
              '{"id":1}',
              request.url.path.endsWith('/0') ? 404 : 200,
            );
          }),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: MyHomePage(title: 'Demo', networkClients: clients),
          ),
        );
        await tester.tap(
          find.text(isDio ? 'Test Dio requests' : 'Test HTTP requests'),
        );
        await tester.pumpAndSettle();
        expect(isDio ? adapter.paths : httpPaths, ['/posts/1', '/posts/0']);
        expect(isDio ? httpPaths : adapter.paths, isEmpty);
        expect(
          find.textContaining(
            isDio
                ? 'Dio: HTTP 200, then expected HTTP 404'
                : 'HTTP: 200, then 404',
          ),
          findsOneWidget,
        );
        expect(find.byType(CircularProgressIndicator), findsNothing);
        await tester.pumpWidget(const SizedBox());
        expect(adapter.closed, isTrue);
      },
    );
  }

  testWidgets(
    'network failures restore the buttons and show a helpful message',
    (tester) async {
      final clients = DemoNetworkClients(
        httpClient: MockClient(
          (_) async => throw http.ClientException('offline'),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: MyHomePage(title: 'Demo', networkClients: clients),
        ),
      );
      await tester.tap(find.text('Test HTTP requests'));
      await tester.pumpAndSettle();
      expect(
        find.text('Request failed. Check your connection and the logger.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Test HTTP requests'),
            )
            .onPressed,
        isNotNull,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
}
