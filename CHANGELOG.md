## 3.0.0

- Add optional OnScreenLog.init and runtime configure APIs for capture enablement, captured message types, and auto-scroll, independently of overlay visibility.
- Expose capture and auto-scroll state plus an isEnabledFor check; disabling capture discards future entries while retaining the session for sharing.
- Demonstrate separate capture, overlay, and auto-scroll switches in the example.

- Display connector traffic as expandable network cards with method/status badges, endpoints, correlation IDs, and elapsed time.
- Add structured HttpLogDetails, LogItem.network, and OnScreenLog.log for custom integrations.
- Pretty-print captured JSON in selectable, scrollable payload panels while preserving full copy/share exports.

- Match filter colors to log types, using outlined/filled selection styles without checkmarks.
- Add state-specific icons to all options menu actions.
- Add a jump-to-latest button with a viewport-based, filter-aware message count; pause automatic following while reading older entries.
- Demonstrate the Dio and HTTP connectors with successful and failing API calls in the example.

- Add Pause logging / Resume logging to the options menu to control capture independently of scrolling.

- **Breaking:** require Flutter >=3.44.3 and Dart >=3.12.0.
- Upgrade all direct dependencies and flutter_lints to their latest stable releases.
- Migrate sharing to SharePlus and ShareParams.
- Upgrade the example to Gradle 8.14, AGP 8.13.2, Kotlin 2.3.21, Java 17, and iOS 15.
- Replace the checked-in Flutter SDK with a local FVM link and exclude development files from publication.
- Apply current formatting/lints and replace the example's obsolete counter test.

- Add independent Dio and HTTP connector packages.
- Add multi-select message type filters and an options menu for auto-scroll, sharing, and clearing.
- Preserve expansion state across filters, reset it on clear, and guard scrolling after detachment.
- Remove a missing asset directory declaration.

## 1.0.0

* Initial Implementation

## 1.0.1

* Updated README.md file

## 1.0.2

* Updated Indexes and code formatting

## 2.0.0

* **New Interface**: Refactored the logger API to simplify logging and improve usability. Removed the need for `.init()`; now the logger is initialized automatically when you use the `LoggerOverlayController` and `LoggerOverlayWidget`.
* **New Methods**: Added `clearAll()` and `shareAll()` methods to the logger for easier log management. The `clearAll()` method clears all logged messages, and `shareAll()` allows sharing all logs via the sharing interface.
* **Updated Libraries**: Updated all used libraries to their latest versions for better compatibility and performance.
