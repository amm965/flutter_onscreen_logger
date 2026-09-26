# flutter_onscreen_logger_dio

Connect `dio` traffic to Flutter On-Screen Logger, including when the overlay
is hidden or absent.

```dart
import 'package:dio/dio.dart';
import 'package:flutter_onscreen_logger_dio/flutter_onscreen_logger_dio.dart';

final dio = Dio();
dio.interceptors.add(OnScreenLoggerInterceptor());
```

Requests log as info; responses below 400 as success; HTTP errors and transport
failures as error. Credentials, query values, and headers are omitted.

Each entry is a structured network card with the HTTP method, URL, phase,
response status, and elapsed time. Matching request/response or failure entries
share a request ID, including when several requests run concurrently. Elapsed
time runs from this interceptor's request callback to its response/error callback.

Bodies are disabled by default. Set `logBodies: true` to include payloads;
stream and multipart bodies are never consumed. Payloads may contain secrets.
Captured JSON maps, lists, and JSON text are pretty-printed in a separate body
section; other text is preserved. Copying or sharing includes all captured details.

Pass `log: (LogItem item) { ... }` to customize the sink. A failing sink does not
break requests. Logs use the core package's in-memory session, available through
`OnScreenLog.shareAll()` without mounting an overlay.
Custom sinks can inspect `item.httpDetails` or forward the complete entry with
`OnScreenLog.log(item)` to preserve the network card presentation.

For repository development, run `flutter pub get`, `flutter analyze`, and
`flutter test` here. The adjacent `pubspec_overrides.yaml` selects the local core.
See the repository README for local path dependency setup. Publish this package
separately before consumers can install it as a hosted dependency.
