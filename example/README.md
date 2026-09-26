# Flutter On-Screen Logger example

Use Flutter 3.44.3 or newer. From this directory run:

```sh
flutter pub get
flutter run
```

The repository's `pubspec_overrides.yaml` resolves the core, Dio connector, and
HTTP connector locally. Published examples use the hosted connector packages;
publish core 3.0.0 and both connector 1.0.0 packages before using those versions.

The example calls `OnScreenLog.init()` at startup with all four capture types.
Capture and auto-scroll default to enabled; the overlay defaults to visible in
debug builds and hidden in profile/release builds. Override these independently
with compile-time defines:

```sh
# Capture no logs, while still being able to inspect the overlay in debug mode.
flutter run --dart-define=LOGGING_ENABLED=false

# Capture a session in the background with no overlay.
flutter run --dart-define=LOGGER_OVERLAY_ENABLED=false

# Start with automatic scrolling disabled.
flutter run --dart-define=LOGGER_AUTO_SCROLL=false

# Release build with all logging disabled.
flutter run --release --dart-define=LOGGING_ENABLED=false
```

`LOGGING_ENABLED` defaults to `true`, `LOGGER_OVERLAY_ENABLED` defaults to
`kDebugMode`, and `LOGGER_AUTO_SCROLL` defaults to `true`. Hiding the overlay
does not pause capture. Applications that keep release capture enabled can call
`OnScreenLog.shareAll()` from a support/settings button to share the session.

For runtime changes, call `OnScreenLog.configure(enabled: false)` to stop capture
or `OnScreenLog.configure(enabled: true)` to resume. Pass `enabledTypes` to limit
capture to a set such as `{LogItemType.error, LogItemType.warning}`, and
`autoScroll` to change the scroll preference. The menu and API share the same
pause/resume and auto-scroll state. Quick filter chips only change visibility;
they do not remove entries from the captured session.

- **Generate Test Log Messages** adds info, error, warning, and success entries.
- **Test Dio requests** uses `Dio` with `OnScreenLoggerInterceptor`.
- **Test HTTP requests** uses `OnScreenLoggerClient` around an HTTP client.

Each network demo requests `https://jsonplaceholder.typicode.com/posts/1`, then
`/posts/0`, to produce 200 and 404 logs. Open the logger using its list toggle.
Dio body logging is enabled only for the public demo data. An internet connection
is required; buttons show progress and connection failures. Clients are closed
on disposal. See `lib/network_demos.dart` for setup and `lib/main.dart` for buttons.

Filters use type colors. The menu provides logging pause/resume, auto-scroll,
sharing, and clearing. When scrolled up, the small bottom-right button counts
filtered messages below the viewport and jumps to the latest entry.

`flutter test` uses mock transports, including an offline failure case, rather
than relying on the public API.

Network requests now appear as compact cards. Tap a card header to expand its
URL, failure details, and captured JSON. Match request/response entries by their
shared request ID; successful and failed responses show status and timing.
