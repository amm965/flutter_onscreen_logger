/// package:http integration for Flutter On-Screen Logger.
library;

import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_onscreen_logger/flutter_onscreen_logger.dart';

/// Wraps an HTTP client to log requests, response status, and failures.
/// Payloads, headers, credentials, and query values are omitted. Response
/// streams remain lazy: chunks and errors are forwarded without buffering.
class OnScreenLoggerClient extends http.BaseClient {
  /// Creates a wrapper. Closing it also closes [inner].
  /// Custom [log] sinks are independent of [OnScreenLog]'s configuration.
  OnScreenLoggerClient(http.Client inner, {void Function(LogItem)? log})
    : _inner = inner,
      _log = log ?? OnScreenLog.log,
      _usesDefaultSink = log == null;

  final http.Client _inner;
  final void Function(LogItem) _log;
  final bool _usesDefaultSink;
  static int _nextRequestId = 0;

  void _record(
    http.BaseRequest request,
    LogItemType type,
    HttpLogPhase phase,
    _RequestContext context, {
    int? status,
    String? error,
  }) {
    try {
      if (_usesDefaultSink && !OnScreenLog.isEnabledFor(type)) return;
      final uri = request.url;
      final target =
          '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}${uri.path}';
      _log(
        LogItem.network(
          type: type,
          details: HttpLogDetails(
            method: request.method,
            url: target,
            phase: phase,
            requestId: context.id,
            statusCode: status,
            duration: phase == HttpLogPhase.request
                ? null
                : context.timer.elapsed,
            error: error,
          ),
        ),
      );
    } catch (_) {
      // Logging must never break network traffic.
    }
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final context = _RequestContext('http-${++_nextRequestId}');
    _record(request, LogItemType.info, HttpLogPhase.request, context);
    try {
      final response = await _inner.send(request);
      context.timer.stop();
      _record(
        request,
        response.statusCode >= 400 ? LogItemType.error : LogItemType.success,
        HttpLogPhase.response,
        context,
        status: response.statusCode,
      );
      final stream = response.stream.transform(
        StreamTransformer<List<int>, List<int>>.fromHandlers(
          handleError:
              (Object error, StackTrace stack, EventSink<List<int>> sink) {
                _record(
                  request,
                  LogItemType.error,
                  HttpLogPhase.error,
                  context,
                  status: response.statusCode,
                  error: 'Response stream failed',
                );
                sink.addError(error, stack);
              },
        ),
      );
      return http.StreamedResponse(
        stream,
        response.statusCode,
        contentLength: response.contentLength,
        request: response.request,
        headers: response.headers,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase,
      );
    } catch (_) {
      context.timer.stop();
      _record(
        request,
        LogItemType.error,
        HttpLogPhase.error,
        context,
        error: 'Request failed',
      );
      rethrow;
    }
  }

  @override
  void close() => _inner.close();
}

class _RequestContext {
  _RequestContext(this.id);

  final String id;
  final Stopwatch timer = Stopwatch()..start();
}
