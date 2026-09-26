/// Dio integration for Flutter On-Screen Logger.
library;

import 'package:dio/dio.dart';
import 'package:flutter_onscreen_logger/flutter_onscreen_logger.dart';

/// Logs traffic without changing Dio's request, response, or error objects.
/// Add an instance to `dio.interceptors`. Headers and bodies are opt-in because
/// they can contain private data. Streams and multipart payloads are omitted.
class OnScreenLoggerInterceptor extends Interceptor {
  /// Creates a logger interceptor. [log] can override the default log sink.
  /// [options] overrides the network capture settings configured on
  /// [OnScreenLog]. [logBodies] remains as a convenience for existing callers.
  OnScreenLoggerInterceptor({
    bool? logBodies,
    this.options,
    void Function(LogItem)? log,
  }) : _legacyLogBodies = logBodies,
       _log = log ?? OnScreenLog.log,
       _usesDefaultSink = log == null;

  /// Per-interceptor network capture settings, overriding global options.
  final NetworkLogOptions? options;

  /// Whether to include both non-streaming body directions as a convenience.
  /// This keeps the original option available; detailed settings use [options].
  final bool? _legacyLogBodies;

  /// Whether the legacy `logBodies` option was enabled.
  bool get logBodies => _legacyLogBodies ?? false;
  final void Function(LogItem) _log;
  final bool _usesDefaultSink;
  final _requests = Expando<_RequestContext>();
  static int _nextRequestId = 0;

  void _record(
    LogItemType type,
    RequestOptions request,
    HttpLogPhase phase,
    _RequestContext context, {
    int? status,
    Object? body,
    Map<String, dynamic>? headers,
    String? error,
  }) {
    try {
      if (_usesDefaultSink && !OnScreenLog.isEnabledFor(type)) return;
      final uri = request.uri;
      var target =
          '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}${uri.path}';
      final configured = options ?? OnScreenLog.networkLogOptions;
      final settings = _legacyLogBodies != null
          ? configured.copyWith(
              includeRequestBody: _legacyLogBodies,
              includeResponseBody: _legacyLogBodies,
            )
          : configured;
      final redactor = settings.redactor;
      if (redactor != null) target = redactor(target);
      final captureBody = phase == HttpLogPhase.request
          ? settings.includeRequestBody
          : settings.includeResponseBody;
      final payload = captureBody && body != null
          ? body is Stream || body is FormData || body is ResponseBody
                ? '[stream or multipart body omitted]'
                : _redact(HttpLogDetails.formatBody(body), redactor)
          : null;
      final captureHeaders = phase == HttpLogPhase.request
          ? settings.includeRequestHeaders
          : settings.includeResponseHeaders;
      final headerText = captureHeaders && headers != null
          ? _redact(HttpLogDetails.formatBody(headers), redactor)
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
                : context.timer?.elapsed,
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
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final context = _RequestContext('dio-${++_nextRequestId}');
    _requests[options] = context;
    _record(
      LogItemType.info,
      options,
      HttpLogPhase.request,
      context,
      body: options.data,
      headers: options.headers,
    );
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final context = _requests[response.requestOptions];
    context?.timer?.stop();
    final status = response.statusCode;
    _record(
      status != null && status >= 400 ? LogItemType.error : LogItemType.success,
      response.requestOptions,
      HttpLogPhase.response,
      context ?? _RequestContext.unobserved('dio-${++_nextRequestId}'),
      status: status,
      body: response.data,
      headers: response.headers.map,
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final context = _requests[err.requestOptions];
    context?.timer?.stop();
    _record(
      LogItemType.error,
      err.requestOptions,
      HttpLogPhase.error,
      context ?? _RequestContext.unobserved('dio-${++_nextRequestId}'),
      status: err.response?.statusCode,
      body: err.response?.data,
      headers: err.response?.headers.map,
      error: err.type.name,
    );
    handler.next(err);
  }
}

class _RequestContext {
  _RequestContext(this.id) : timer = Stopwatch()..start();

  _RequestContext.unobserved(this.id) : timer = null;

  final String id;
  final Stopwatch? timer;
}
