# flutter_onscreen_logger_dio

Connect `dio` traffic to Flutter On-Screen Logger, including when the overlay
is hidden or absent.

```dart
import 'package:dio/dio.dart';
import 'package:flutter_onscreen_logger/flutter_onscreen_logger.dart';
import 'package:flutter_onscreen_logger_dio/flutter_onscreen_logger_dio.dart';
// Import your app's LogRedactor utility when using it below.

final dio = Dio();
dio.interceptors.add(OnScreenLoggerInterceptor());
```

Requests log as info; responses below 400 as success; HTTP errors and transport
failures as error. URL credentials and query values are omitted. Headers and
bodies are disabled by default.

Each entry is a structured network card with the HTTP method, URL, phase,
response status, and elapsed time. Matching request/response or failure entries
share a request ID, including when several requests run concurrently. Elapsed
time runs from this interceptor's request callback to its response/error callback.

Configure capture globally with `OnScreenLog.init(networkLogOptions: ...)`, or
override it for this interceptor:

```dart
OnScreenLoggerInterceptor(
  options: NetworkLogOptions(
    includeRequestHeaders: true,
    includeResponseHeaders: true,
    includeRequestBody: true,
    includeResponseBody: true,
    redactor: LogRedactor.redact,
  ),
)
```

The redactor receives each formatted header/body section and returns the text
stored in the session. Use an app-specific redactor for credentials and other
private fields. The original `logBodies: true` option remains supported as a
shortcut to include both bodies. Stream and multipart bodies are never consumed.
Captured JSON maps, lists, and JSON text are pretty-printed; other text is
preserved. Copying or sharing includes the same redacted details.

Pass `log: (LogItem item) { ... }` to customize the sink. A failing sink does not
break requests. Logs use the core package's in-memory session, available through
`OnScreenLog.shareAll()` without mounting an overlay.
Custom sinks can inspect `item.httpDetails` or forward the complete entry with
`OnScreenLog.log(item)` to preserve the network card presentation.

For repository development, run `flutter pub get`, `flutter analyze`, and
`flutter test` here. The adjacent `pubspec_overrides.yaml` selects the local core.
See the repository README for local path dependency setup. Publish this package
separately before consumers can install it as a hosted dependency.
