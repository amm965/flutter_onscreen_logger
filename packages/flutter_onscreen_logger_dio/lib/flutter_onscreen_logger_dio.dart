/// Dio integration for Flutter On-Screen Logger.
library;

import 'package:dio/dio.dart';
import 'package:flutter_onscreen_logger/flutter_onscreen_logger.dart';

/// Logs traffic without changing Dio's request, response, or error objects.
/// Add an instance to `dio.interceptors`. Bodies are opt-in because they can
/// contain private data. Streams and multipart payloads are never consumed.
class OnScreenLoggerInterceptor extends Interceptor {
  /// Creates a logger interceptor. [log] can override the default log sink.
  /// Custom sinks are independent of [OnScreenLog]'s capture configuration.
  OnScreenLoggerInterceptor({
    this.logBodies = false,
    void Function(LogItem)? log,
  }) : _log = log ?? OnScreenLog.log,
       _usesDefaultSink = log == null;

  /// Whether to include non-streaming payloads (may contain sensitive data).
  final bool logBodies;
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
    String? error,
  }) {
    try {
      if (_usesDefaultSink && !OnScreenLog.isEnabledFor(type)) return;
      // Omit credentials, query values, and headers from automatic logs.
      final uri = request.uri;
      final target =
          '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}${uri.path}';
      final payload = logBodies && body != null
          ? body is Stream || body is FormData || body is ResponseBody
                ? '[stream or multipart body omitted]'
                : HttpLogDetails.formatBody(body)
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
            body: payload,
            error: error,
          ),
        ),
      );
    } catch (_) {
      // Logging must never break network traffic.
    }
  }

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
