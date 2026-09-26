/// package:http integration for Flutter On-Screen Logger.
library;

import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_onscreen_logger/flutter_onscreen_logger.dart';

/// Wraps an HTTP client to log requests, response status, and failures.
/// Headers and request bodies are opt-in. Response streams remain lazy: chunks
/// and errors are forwarded without buffering or being consumed for logging.
class OnScreenLoggerClient extends http.BaseClient {
  /// Creates a wrapper. Closing it also closes [inner].
  /// Custom [log] sinks are independent of [OnScreenLog]'s configuration.
  OnScreenLoggerClient(
    http.Client inner, {
    this.options,
    void Function(LogItem)? log,
  }) : _inner = inner,
       _log = log ?? OnScreenLog.log,
       _usesDefaultSink = log == null;

  final http.Client _inner;

  /// Per-client network capture settings, overriding global options.
  final NetworkLogOptions? options;
  final void Function(LogItem) _log;
  final bool _usesDefaultSink;
  static int _nextRequestId = 0;

  void _record(
    http.BaseRequest request,
    LogItemType type,
    HttpLogPhase phase,
    _RequestContext context, {
    int? status,
    Map<String, String>? headers,
    Object? body,
    String? error,
  }) {
    try {
      if (_usesDefaultSink && !OnScreenLog.isEnabledFor(type)) return;
      final uri = request.url;
      final settings = options ?? OnScreenLog.networkLogOptions;
      final redactor = settings.redactor;
      var target =
          '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}${uri.path}';
      if (redactor != null) target = redactor(target);
      final captureHeaders = phase == HttpLogPhase.request
          ? settings.includeRequestHeaders
          : settings.includeResponseHeaders;
      final headerText = captureHeaders && headers != null
          ? _redact(HttpLogDetails.formatBody(headers), redactor)
          : null;
      final captureBody = phase == HttpLogPhase.request
          ? settings.includeRequestBody
          : settings.includeResponseBody;
      final payload = captureBody && body != null
          ? _redact(HttpLogDetails.formatBody(body), redactor)
          : null;
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
            headers: headerText,
            body: payload,
            error: error == null ? null : _redact(error, redactor),
          ),
        ),
      );
    } catch (_) {
      // Logging must never break network traffic.
    }
  }

  String _redact(String text, NetworkLogRedactor? redactor) =>
      redactor == null ? text : redactor(text);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final context = _RequestContext('http-${++_nextRequestId}');
    _record(
      request,
      LogItemType.info,
      HttpLogPhase.request,
      context,
      headers: request.headers,
      body: request is http.Request ? request.body : null,
    );
    try {
      final response = await _inner.send(request);
      context.timer.stop();
      _record(
        request,
        response.statusCode >= 400 ? LogItemType.error : LogItemType.success,
        HttpLogPhase.response,
        context,
        status: response.statusCode,
        headers: response.headers,
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
