import 'dart:convert';

/// The stage of a network operation represented by an entry.
enum HttpLogPhase {
  /// An outgoing request.
  request,

  /// A received response, including HTTP error status codes.
  response,

  /// A request or response-stream failure.
  error,
}

/// A snapshot of network information, independent of any HTTP client package.
/// Connectors supply sanitized URLs and opt-in body text. Custom callers are
/// responsible for choosing which information is suitable to capture and share.
class HttpLogDetails {
  /// Creates structured details for a network log card and its text export.
  const HttpLogDetails({
    required this.method,
    required this.url,
    required this.phase,
    this.requestId,
    this.statusCode,
    this.duration,
    this.headers,
    this.body,
    this.error,
  });

  /// HTTP method, such as GET or POST.
  final String method;

  /// The captured URL, with any redaction already applied.
  final String url;

  /// Whether this entry records a request, response, or failure.
  final HttpLogPhase phase;

  /// Identifier shared by entries belonging to the same request.
  final String? requestId;

  /// HTTP response status, if a response was received.
  final int? statusCode;

  /// Elapsed time as measured by the connector at this stage.
  final Duration? duration;

  /// Formatted, already-redacted headers captured for this request or response.
  final String? headers;

  /// Captured payload text, usually formatted JSON. Null means not captured.
  final String? body;

  /// Failure information suitable for display and sharing.
  final String? error;

  /// A readable version containing every captured field, used for copy/share.
  String toPlainText() => [
    '${phase.name.toUpperCase()} $method $url',
    if (requestId != null) 'Request ID: $requestId',
    if (statusCode != null) 'HTTP status: $statusCode',
    if (duration != null) 'Elapsed: ${duration!.inMilliseconds} ms',
    if (error != null) 'Failure: $error',
    if (headers != null) 'Headers:\n$headers',
    if (body != null) 'Body:\n$body',
  ].join('\n');

  /// Pretty-prints JSON maps, lists, or JSON text; preserves other text.
  /// Payloads are formatted when logged, so later data mutations cannot change
  /// the displayed or exported snapshot. Streams should never be passed here.
  static String formatBody(Object? body) {
    Object? value = body;
    if (value is String) {
      final text = value;
      try {
        value = jsonDecode(value);
      } on FormatException {
        return text;
      }
    }
    try {
      return const JsonEncoder.withIndent('  ').convert(value);
    } catch (_) {
      try {
        return body.toString();
      } catch (_) {
        return '[body could not be formatted]';
      }
    }
  }
}
