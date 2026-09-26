## 3.0.0

### Added

- Add independent Dio and HTTP connector packages with example integrations.
- Add structured network log details and compact, expandable request cards with
  status, duration, and correlated request IDs.
- Add type filters, options for pause/resume, auto-scroll, sharing, and clearing,
  plus a jump-to-latest button with a count of messages below the viewport.
- Add programmatic capture controls for enabled state, accepted message types,
  and auto-scroll. Capture is independent of overlay visibility and preserves
  existing entries for sharing when paused or disabled.
- Add examples for background session capture and production support sharing.

### Updated

- **Breaking:** require Flutter 3.44.3 or newer and Dart 3.12 or newer.
- Upgrade direct dependencies and Flutter lints to current stable releases.
- Upgrade the example to Gradle 8.14, Android Gradle Plugin 8.13.2, Kotlin
  2.3.21, Java 17, and iOS 15.
- Replace the checked-in Flutter SDK with a local FVM version and exclude
  development files from publication.
- Improve logger styling, preserve expansion state across filters, and guard
  scrolling after the overlay detaches.

## 2.0.0

- Refactor the logger interface and initialize the controller automatically.
- Add `clearAll()` and `shareAll()` methods.
- Update dependencies.

## 1.0.2

- Update indexes and formatting.

## 1.0.1

- Update the README.

## 1.0.0

- Initial release.
