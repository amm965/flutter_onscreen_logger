/// Redacts captured network log text before it is stored or shared.
///
/// The callback receives one formatted section, such as a JSON header map or
/// request body, and must return the text safe to display and export.
typedef NetworkLogRedactor = String Function(String text);

/// Controls which parts of HTTP requests and responses connectors capture.
///
/// Headers and bodies are excluded by default because they can contain
/// credentials or personal data. Supply [redactor] when enabling capture to
/// remove application-specific secrets before they enter the log session.
class NetworkLogOptions {
  /// Creates network capture options. All potentially sensitive sections are
  /// disabled by default.
  const NetworkLogOptions({
    this.includeRequestHeaders = false,
    this.includeResponseHeaders = false,
    this.includeRequestBody = false,
    this.includeResponseBody = false,
    this.redactor,
  });

  /// Whether outgoing request headers are captured.
  final bool includeRequestHeaders;

  /// Whether response headers are captured.
  final bool includeResponseHeaders;

  /// Whether non-streaming request payloads are captured.
  final bool includeRequestBody;

  /// Whether response payloads are captured. Connectors may omit response
  /// bodies when reading them would consume or buffer a caller-owned stream.
  final bool includeResponseBody;

  /// Redacts each included text section before it is logged.
  final NetworkLogRedactor? redactor;

  /// Returns a copy with selected settings replaced.
  NetworkLogOptions copyWith({
    bool? includeRequestHeaders,
    bool? includeResponseHeaders,
    bool? includeRequestBody,
    bool? includeResponseBody,
    NetworkLogRedactor? redactor,
  }) => NetworkLogOptions(
    includeRequestHeaders: includeRequestHeaders ?? this.includeRequestHeaders,
    includeResponseHeaders:
        includeResponseHeaders ?? this.includeResponseHeaders,
    includeRequestBody: includeRequestBody ?? this.includeRequestBody,
    includeResponseBody: includeResponseBody ?? this.includeResponseBody,
    redactor: redactor ?? this.redactor,
  );
}
