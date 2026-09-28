# Flutter On-Screen Logger

[![Pub Package](https://img.shields.io/pub/v/flutter_onscreen_logger)](https://pub.dev/packages/flutter_onscreen_logger)
[![Pub Package](https://img.shields.io/badge/flutter-%3E%3D3.44.3-green)](https://flutter.dev/)
[![GitHub Repo stars](https://img.shields.io/github/stars/amm965/flutter_onscreen_logger?style=social)](https://github.com/amm965/flutter_onscreen_logger)

A Flutter package that displays logs over your app for easier debugging and can
capture a session without an overlay for sharing through your support flow.

![flutter_onscreen_logger](https://media3.giphy.com/media/v1.Y2lkPTc5MGI3NjExZXlwNmRmajJ6dzJ6ZHhhdTAxZDBoYzl3dzQzYWs0bGZoMXc3MmhzbiZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/lJR4AQpB2FzPVUpgry/giphy.gif)
![flutter_onscreen_logger](https://media3.giphy.com/media/v1.Y2lkPTc5MGI3NjExZWxhanRtNnRsajVmdzV1dGI5OXJ6NW51a3gyb3ZicW82N2ZnMzl1ZyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/JlX7JM0AX904SKk2AB/giphy.gif)

## Features

- Log exceptions and errors in a user-friendly way.
- Easily integrate with Dio for HTTP request logging.
- Simple API for logging custom messages.
- Customizable display options for logs.
- Programmatic capture controls for development, production, and runtime settings.

## Getting Started

1. Add the package to your `pubspec.yaml` file:

    ```yaml
    dependencies:
      flutter_onscreen_logger: ^3.0.0
    ```

2. Configure your `main.dart` to integrate the library:

    - Wrap your `runApp()` method in `main()` with `runZonedGuarded()` to handle errors globally.
    - Optionally call `OnScreenLog.init()` to choose capture and scrolling options.
    - Call `OnScreenLog.onError()` during startup to capture Flutter framework errors.
    - Log asynchronous errors received by the zone's error callback.

    ```dart
    void main() {
      runZonedGuarded(() {
        WidgetsFlutterBinding.ensureInitialized();

        OnScreenLog.init(
          enabled: true,
          enabledTypes: LogItemType.values.toSet(),
          autoScroll: true,
        );
        OnScreenLog.onError();

        //...other code...
        
        runApp(MyApp());
      }, (error, stack) {
        OnScreenLog.e(title: error.toString(), message: stack.toString());
      });
    }
    ```

    - Wrap your `MaterialApp()` widget with a `Stack()` and `Directionality()` widgets.
    - Add `LoggerOverlayWidget()` widget below it.
    - Show the overlay when useful for your app. Its visibility is independent of capture. This example displays it only in debug mode (`kDebugMode` comes from `package:flutter/foundation.dart`).

   ```dart
   Directionality(
      textDirection: TextDirection.ltr, 
      child: Stack(
          children: [
            MaterialApp(
              //...other material app properties...
              home: MyHomePage(title: 'MyApp'),
            ),
            if (kDebugMode) LoggerOverlayWidget(),
          ],
        ),
    );
   ```

## Usage

You can use the on-screen logger to log your own custom message throughout your project using the
following methods:

### e() - Log Errors

Logs error messages with a red color.

   ```dart
   OnScreenLog.e(
     title: 'Network Error',
     message: 'Unable to fetch data from server.',
   );
   ```
   
### i() - Log Info

Logs info messages with a white color.

   ```dart
   OnScreenLog.i(
     title: 'API Response Received!',
     message: '* API Response:\n$data',
   );
   ```
   
### s() - Log Success

Logs success messages with a green color.

   ```dart
   OnScreenLog.s(
     title: 'Login Successful',
     message: 'User has logged in successfully.',
   );
   ```
   
### w() - Log Warnings

Logs warning messages with a orange color.

   ```dart
   OnScreenLog.w(
     title: 'Low Disk Space',
     message: 'Disk space is running low, consider cleaning up.',
   );
   ```
   
### shareAll() - Share All Logs

Allows you to share all the log entries that have been captured so far. This method will gather the logs and open a sharing interface for the user to share the log messages.

   ```dart
   OnScreenLog.shareAll();
   ```

### clearAll() - Clear All Logs

Clears all log entries currently stored in the logger, effectively resetting the log data. This is useful if you want to start a new logging session or remove sensitive log data.

   ```dart
   OnScreenLog.clearAll();
   ```

## Configure capture and scrolling

Call `OnScreenLog.init()` before your first log to choose the session's initial
settings. Initialization is optional: the logger still initializes lazily with
capture enabled, every message type enabled, and auto-scroll enabled.

```dart
OnScreenLog.init(
  enabled: true,
  enabledTypes: {LogItemType.error, LogItemType.warning},
  autoScroll: false,
);
```

| Option | Default | Effect |
| --- | --- | --- |
| `enabled` | `true` | Whether new entries are captured at all, including when the overlay is absent. |
| `enabledTypes` | Every `LogItemType` | Types accepted into the session. An empty set captures nothing. |
| `autoScroll` | `true` | Whether the overlay follows new entries while already at the bottom. |
| `networkLogOptions` | `NetworkLogOptions()` | Which HTTP headers and bodies connectors capture and the redactor applied before storage. |

Disabling capture discards future entries from `OnScreenLog` methods, the default
Dio/HTTP connectors, and installed Flutter error capture. Existing entries remain
available to share or clear. Resuming records new entries only; discarded entries
are never replayed. Removing or collapsing the overlay does not change these
settings. Connectors using a custom `log` callback have their own sink; these
settings apply when that callback submits entries to `OnScreenLog`.

Change individual settings at runtime without resetting the others:

```dart
OnScreenLog.configure(enabled: false); // Stop capture, retain existing logs.
OnScreenLog.configure(enabled: true); // Resume capture.
OnScreenLog.configure(
  enabledTypes: {LogItemType.error, LogItemType.warning},
  autoScroll: false,
);
OnScreenLog.configure(enabledTypes: LogItemType.values.toSet());
```

`configure()` updates only the supplied options. Calling `init()` again applies
its complete settings, including defaults for omitted options, to the existing
session. Neither call clears captured logs or changes the overlay's quick filters.
The menu's pause/resume and auto-scroll actions use the same state as these APIs.

Read `OnScreenLog.isEnabled`, `OnScreenLog.isAutoScrollEnabled`, and the immutable
`OnScreenLog.enabledTypes` set to inspect the current settings. Use
`OnScreenLog.isEnabledFor(type)` before preparing expensive log data:

```dart
if (OnScreenLog.isEnabledFor(LogItemType.info)) {
  OnScreenLog.i(message: buildDiagnosticReport());
}
```

### Capture only during development

Choose this if release builds should capture no session logs. Existing logging
calls can stay in your application code:

```dart
OnScreenLog.init(enabled: kDebugMode);

// In the Stack around your MaterialApp:
if (kDebugMode) LoggerOverlayWidget(),
```

### Capture production support sessions without an overlay

Keep capture enabled and display the overlay only during development. Your
production settings or support page can offer a share button:

```dart
OnScreenLog.init(enabled: true);

// In the Stack around your MaterialApp:
if (kDebugMode) LoggerOverlayWidget(),

// In your settings/support page:
TextButton.icon(
  onPressed: OnScreenLog.shareAll,
  icon: const Icon(Icons.share),
  label: const Text('Share session logs'),
),
```

To reduce production capture to warnings and errors while retaining every type
during development:

```dart
OnScreenLog.init(
  enabled: true,
  enabledTypes: kDebugMode
      ? LogItemType.values.toSet()
      : {LogItemType.warning, LogItemType.error},
  autoScroll: kDebugMode,
);

// Later, apply an app setting without changing the type selection:
OnScreenLog.configure(enabled: captureEnabledByUser);
```

## Quick filters and options

Tap the **info**, **success**, **warning**, and **error** chips to include or
exclude types independently. All types start selected; deselecting every type
shows an empty view. These filters only affect the view, so **Share all** still
shares the complete captured session. In contrast, `enabledTypes` controls which
new entries are stored in the first place. The top-right **Logger options** menu contains
**Pause logging** / **Resume logging**, **Auto-scroll** (configurable at startup),
**Share all**, and **Clear all**. Pausing discards incoming entries, including
connector logs, while keeping existing entries available. It remains paused
when the overlay is collapsed; resuming captures only new entries and does not
replay skipped messages. This is independent of auto-scroll.

Filter chips use the same colors as their message types: outlined when excluded
and filled when selected. Every menu action has an icon; toggle icons reflect
the current logging/auto-scroll state.

When newer messages are below the viewport, a small button at the bottom right
shows how many **filtered messages are below the last visible entry**. Partially
visible entries count as visible. Tap it to jump to the actual latest entry;
it disappears at the bottom. Scrolling up suspends automatic following so new
messages do not interrupt reading. Returning to the bottom resumes following
if auto-scroll is enabled. Jumping does not change the auto-scroll preference.

## Automatic network logging

Two independent connector packages live in `packages/`. They use the same
logger session whether or not `LoggerOverlayWidget` is mounted.

### Dio

```dart
import 'package:dio/dio.dart';
import 'package:flutter_onscreen_logger_dio/flutter_onscreen_logger_dio.dart';

final dio = Dio();
dio.interceptors.add(OnScreenLoggerInterceptor());
```

### package:http

HTTP uses a client wrapper because it has no Dio-style interceptor API. Make
requests through the wrapper (top-level `http.get` calls are not intercepted).

```dart
import 'package:http/http.dart' as http;
import 'package:flutter_onscreen_logger_http/flutter_onscreen_logger_http.dart';

final client = OnScreenLoggerClient(http.Client());
final response = await client.get(Uri.parse('https://example.com'));
client.close(); // Also closes the wrapped client.
```

For local development, add the desired connector with a path dependency:

```yaml
dependencies:
  flutter_onscreen_logger:
    path: /path/to/flutter_onscreen_logger
  flutter_onscreen_logger_dio:
    path: /path/to/flutter_onscreen_logger/packages/flutter_onscreen_logger_dio
  # Or flutter_onscreen_logger_http with its corresponding path.
dependency_overrides:
  flutter_onscreen_logger:
    path: /path/to/flutter_onscreen_logger
```

The connectors log methods, URL paths, response status, and failures. URL
credentials and query values are omitted. Headers and bodies stay off by
default. Enable selected fields and redact their formatted text before it enters
the session:

```dart
OnScreenLog.init(
  networkLogOptions: NetworkLogOptions(
    includeRequestHeaders: true,
    includeResponseHeaders: true,
    includeRequestBody: true,
    includeResponseBody: true,
    redactor: LogRedactor.redact, // Your app's redactor, e.g. token/password rules.
  ),
);
```

`NetworkLogOptions` can also be passed to an individual
`OnScreenLoggerInterceptor(options: ...)` or `OnScreenLoggerClient(options: ...)`
to override the global setting. Redaction runs before the entry is stored, so
the overlay, copy action, and shared session use the same sanitized snapshot.
Implement the callback to return safe text, for example by redacting sensitive
JSON keys and token patterns. `includeResponseBody` captures decoded Dio
responses; the HTTP connector does not read or buffer response streams. It
captures buffered `http.Request` bodies only when enabled. Each connector
accepts an optional `log: (LogItem item) { ... }` callback for a custom sink.
Logging failures do not interrupt requests.

## Capturing a session without the overlay

Keep `OnScreenLog` enabled and call `OnScreenLog.i/e/w/s` or use either connector
without adding the widget. Configure `enabledTypes` to choose what is captured.
Offer `OnScreenLog.shareAll()` in your app's support flow to export the captured
session. Logs are held **in memory for the current process**, and written to a
temporary file when shared; they are not persisted across app restarts. This
does not schedule background execution or collect logs from other isolates.

## Developing the packages

Run `flutter pub get`, `flutter analyze`, and `flutter test` in the repository
root and in each connector directory. Connector `pubspec_overrides.yaml` files
resolve the core package locally and are excluded from publication by pub.
The connector packages must be published separately before hosted dependencies
can be used by consumers.


## Version 3 toolchain and migration

Version 3 requires **Flutter 3.44.3 or newer** and **Dart 3.12 or newer**.
The repository pins Flutter 3.44.3 in `.fvmrc`; run `fvm use 3.44.3` to install/select
that SDK on another machine. SDK installations are excluded from Git and pub
archives. The `.fvm/flutter_sdk` link is generated locally by FVM.

The Android example uses **Gradle 9.7.1**, **Android Gradle Plugin 9.3.3**,
**Kotlin 2.4.20**, and Java **17** source/target compatibility. Run Gradle with
JDK 17 or newer (Flutter can use Android Studio's bundled JDK). The iOS example
targets iOS 15 or newer. Update consuming applications' native build settings
before upgrading from version 2, since the latest plugin dependencies have
higher platform/toolchain requirements.

Direct dependencies are updated to fluttertoast 10.0.0, get 4.7.3, intl 0.20.3,
path_provider 2.1.6, and share_plus 13.3.0. Sharing uses the current
`SharePlus.instance.share(ShareParams(...))` API; the public `OnScreenLog` calls
remain compatible. Some transitive dependencies are constrained by Flutter or
upstream plugins; this project does not force incompatible dependency overrides.

Before publishing, run the following with the selected SDK:

```sh
fvm flutter pub get
fvm flutter analyze
fvm dart format --output=none --set-exit-if-changed lib test example/lib example/test packages
fvm flutter test
fvm dart pub outdated --no-dev-dependencies --up-to-date --no-dependency-overrides
fvm dart pub publish --dry-run
```

Run analysis and tests in `example/` and each connector directory too. Publish
the core version 3.0.0 package before the connectors, which depend on `^3.0.0`.
Pub.dev assigns the final hosted score after publication and reanalysis.

The root `.pubignore` keeps the nested connector sources out of the core package
archive. Export each connector directory outside the repository before
publishing it, so it is checked as its own package:

```sh
mkdir -p /tmp/logger-release
git archive HEAD packages/flutter_onscreen_logger_dio | tar -x -C /tmp/logger-release
cd /tmp/logger-release/packages/flutter_onscreen_logger_dio
fvm dart pub publish --dry-run
```

Repeat with `flutter_onscreen_logger_http` in the archive path and working
directory for the HTTP connector. Publish the core package first so the
connectors' `^3.0.0` dependency is available.


### Try both connectors in the example

Run `fvm flutter pub get` and `fvm flutter run` from `example/`. Its local
`pubspec_overrides.yaml` selects the connector packages from this repository.
Tap **Test Dio requests** or **Test HTTP requests**. Each makes two GET requests
to [JSONPlaceholder](https://jsonplaceholder.typicode.com/guide/): `/posts/1`
(200) and `/posts/0` (404), demonstrating automatic request, success, and error
logs. These calls need an internet connection and send no credentials. The Dio
demo enables body logging for this public test data; the HTTP demo logs metadata.
Both clients are closed when the example screen is disposed. Network button
tests use mock transports, so the automated suite runs offline.

### Reading network logs

Dio and HTTP entries use dedicated network cards. The collapsed summary shows
the method, request/response/failure stage, HTTP status when available, endpoint,
elapsed time, and a request ID shared by related entries. Timing measures the
Dio response or failure, and HTTP time to response headers; it is not a measure
of downloading an HTTP response stream.

Tap a card's header to inspect the full captured URL, failure category, and
payload. Dio bodies captured with `logBodies: true` are formatted as indented
JSON when possible. Large bodies scroll inside a bounded panel, so the **Copy
log** action stays accessible. Copying and sharing include the entire captured
body, not just the visible portion. HTTP streams remain unbuffered and its
connector continues to log metadata only. Headers, credentials, and query values
remain omitted by the connectors.

You can also submit structured network entries from a custom integration:

```dart
OnScreenLog.log(LogItem.network(
  type: LogItemType.success,
  details: HttpLogDetails(
    method: 'GET',
    url: 'https://api.example.com/orders/42',
    phase: HttpLogPhase.response,
    requestId: 'orders-42',
    statusCode: 200,
    duration: const Duration(milliseconds: 120),
    body: HttpLogDetails.formatBody({'id': 42, 'status': 'delivered'}),
  ),
));
```

Custom integrations choose which URL and payload information to capture.
`LogItem.network` keeps the card and its text export consistent. Existing
`OnScreenLog.i/e/w/s` calls and plain `LogItem` entries keep their original layout.
