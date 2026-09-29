# flutter_onscreen_logger_http

Connect `http` traffic to Flutter On-Screen Logger, including when the overlay
is hidden or absent.

```dart
import 'package:http/http.dart' as http;
import 'package:flutter_onscreen_logger/flutter_onscreen_logger.dart';
import 'package:flutter_onscreen_logger_http/flutter_onscreen_logger_http.dart';
// Import your app's LogRedactor utility when using it below.


final client = OnScreenLoggerClient(http.Client());
```

Requests log as info; responses below 400 as success; HTTP errors and transport
failures as error. URL credentials and query values are omitted. Headers and
bodies are disabled by default.

Each entry is a structured network card with the HTTP method, URL, phase,
response status, and elapsed time. Matching request/response or failure entries
share a request ID, including when several requests run concurrently. Elapsed
time measures receipt of response headers; it excludes reading the body.

Use this client for all requests; top-level `http.get` calls bypass it.
Configure global or per-client capture, including headers and buffered request
bodies. Redact captured values before storage:

```dart
final client = OnScreenLoggerClient(
  http.Client(),
  options: NetworkLogOptions(
    includeRequestHeaders: true,
    includeResponseHeaders: true,
    includeRequestBody: true,
    redactor: LogRedactor.redact,
  ),
);
```

The redactor receives formatted text for each captured section. Use an
app-specific implementation for private fields. Response streams are never
read or buffered for logging; stream errors are logged and forwarded.
Call `client.close()` when done; this also closes the wrapped client.

Pass `log: (LogItem item) { ... }` to customize the sink. A failing sink does not
break requests. Logs use the core package's in-memory session, available through
`OnScreenLog.shareAll()` without mounting an overlay.
Custom sinks can inspect `item.httpDetails` or forward the complete entry with
`OnScreenLog.log(item)` to preserve the network card presentation. Copying and
sharing include all captured details.

For repository development, run `flutter pub get`, `flutter analyze`, and
`flutter test` here. The adjacent `pubspec_overrides.yaml` selects the local core.
See the repository README for local path dependency setup. Publish this package
separately before consumers can install it as a hosted dependency.
