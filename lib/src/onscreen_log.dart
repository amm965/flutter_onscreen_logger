import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'data/log_item_model.dart';
import 'data/log_item_type.dart';
import 'logger_overlay/controllers/logger_overlay_controller.dart';

/// This class provides an interface for logging messages to an on-screen logger.
class OnScreenLog {
  OnScreenLog._internal(); // Private constructor to prevent instantiation

  static LoggerOverlayController get _loggerController {
    if (!Get.isRegistered<LoggerOverlayController>()) {
      Get.put(LoggerOverlayController());
    }
    return Get.find();
  }

  /// Initializes the shared logger with capture and scrolling options.
  ///
  /// Call before emitting logs to control capture from the start. Initialization
  /// is optional: without it, all types are captured and auto-scroll is enabled.
  /// [enabled] controls capture whether or not the overlay is mounted. An empty
  /// [enabledTypes] set captures nothing; overlay chips only filter the view.
  /// Calling this again reapplies these defaults without clearing stored logs
  /// or changing overlay visibility. Use [configure] for partial updates.
  static void init({
    bool enabled = true,
    Set<LogItemType> enabledTypes = const {
      LogItemType.info,
      LogItemType.success,
      LogItemType.warning,
      LogItemType.error,
    },
    bool autoScroll = true,
  }) => configure(
    enabled: enabled,
    enabledTypes: enabledTypes,
    autoScroll: autoScroll,
  );

  /// Updates only the supplied options for the current session.
  ///
  /// Disabled logging or excluded types discard new entries without replay.
  /// Existing entries remain available to share or clear. The pause/resume and
  /// auto-scroll menu actions use the same settings. [enabledTypes] is copied
  /// so later changes to the caller's set cannot alter capture unexpectedly.
  static void configure({
    bool? enabled,
    Set<LogItemType>? enabledTypes,
    bool? autoScroll,
  }) => _loggerController.configure(
    enabled: enabled,
    enabledTypes: enabledTypes,
    autoScroll: autoScroll,
  );

  /// Whether capture is enabled, independently of overlay visibility.
  /// Individual types can still be excluded by [enabledTypes].
  static bool get isEnabled => !_loggerController.isLoggingPaused.value;

  /// Whether the overlay is configured to follow new messages automatically.
  /// Scrolling up temporarily suspends following without changing this setting.
  static bool get isAutoScrollEnabled => _loggerController.autoScroll.value;

  /// An immutable snapshot of the types eligible for capture.
  static Set<LogItemType> get enabledTypes => _loggerController.enabledTypes;

  /// Whether a new [type] entry will be captured with the current settings.
  /// Can be checked before constructing expensive custom log payloads.
  static bool isEnabledFor(LogItemType type) =>
      _loggerController.isEnabledFor(type);

  /// Sets up error handling to log Flutter errors automatically.
  ///
  /// This method replaces the default error widget builder and
  /// `FlutterError.onError` to log uncaught Flutter exceptions to the logger.
  static void onError() {
    ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
      _onFlutterException(errorDetails);
      return const Center(
        child: Text('An error occurred. Check logs for details.'),
      );
    };

    FlutterError.onError = _onFlutterException;
  }

  /// Handles Flutter exceptions and logs them as error messages.
  ///
  /// This is used internally by the `onError` method to process and log
  /// uncaught Flutter errors.
  static void _onFlutterException(FlutterErrorDetails errorDetails) {
    if (!isEnabledFor(LogItemType.error)) return;
    try {
      Timer(
        const Duration(milliseconds: 100),
        () => _loggerController.log(
          LogItem(
            type: LogItemType.error,
            title: errorDetails.exception.toString(),
            description: errorDetails.stack.toString(),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error logging exception to ScreenLog: ${e.toString()}');
    }
  }

  /// Records a custom entry while preserving structured network details.
  /// Respects capture types and enabled state, just like the convenience methods.
  static void log(LogItem item) => _loggerController.log(item);

  /// Logs an informational message.
  ///
  /// - [title]: Optional title for the log message.
  /// - [message]: The content of the log message.
  static void i({String? title, required String message}) =>
      _log(LogItemType.info, title, message);

  /// Logs a success message.
  ///
  /// - [title]: Optional title for the log message.
  /// - [message]: The content of the log message.
  static void s({String? title, required String message}) =>
      _log(LogItemType.success, title, message);

  /// Logs an error message.
  ///
  /// - [title]: Optional title for the log message.
  /// - [message]: The content of the log message.
  static void e({String? title, required String message}) =>
      _log(LogItemType.error, title, message);

  /// Logs a warning message.
  ///
  /// - [title]: Optional title for the log message.
  /// - [message]: The content of the log message.
  static void w({String? title, required String message}) =>
      _log(LogItemType.warning, title, message);

  /// Shares all logged messages.
  ///
  /// This method saves the current log messages and opens the sharing interface
  /// so the user can share the logs.
  static void shareAll() => _loggerController.saveAndShareLogItems();

  /// Clears all logged messages.
  ///
  /// This method removes all log entries currently stored in the logger.
  static void clearAll() => _loggerController.clearAll();

  /// Helper method to log messages of various types.
  ///
  /// - [type]: The type of log item (info, success, error, warning).
  /// - [title]: Optional title for the log message.
  /// - [message]: The content of the log message.
  static void _log(LogItemType type, String? title, String message) {
    if (!isEnabledFor(type)) return;
    _loggerController.log(
      LogItem(type: type, title: title, description: message),
    );
  }
}
