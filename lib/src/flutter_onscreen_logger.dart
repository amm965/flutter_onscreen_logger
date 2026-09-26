import 'dart:async';

import 'package:flutter/material.dart';

import 'data/log_item_model.dart';
import 'data/log_item_type.dart';
import 'data/network_log_options.dart';
import 'onscreen_log.dart';

/// This class provides an interface for logging messages to an on-screen logger.
/// It has been marked as [Deprecated] and should be replaced with [OnScreenLog].
///
/// Use this class to log messages, handle Flutter errors, or initialize the logger overlay.
@Deprecated('Use OnScreenLog instead!')
class OnscreenLogger {
  /// Private constructor to prevent instantiation.
  /// This class uses static methods and cannot be instantiated directly.
  OnscreenLogger._();

  /// Initializes the shared session using [OnScreenLog.init].
  /// Prefer [OnScreenLog] for new integrations. Reinitialization retains logs.
  static void init({
    bool enabled = true,
    Set<LogItemType> enabledTypes = const {
      LogItemType.info,
      LogItemType.success,
      LogItemType.warning,
      LogItemType.error,
    },
    bool autoScroll = true,
    NetworkLogOptions networkLogOptions = const NetworkLogOptions(),
  }) => OnScreenLog.init(
    enabled: enabled,
    enabledTypes: enabledTypes,
    autoScroll: autoScroll,
    networkLogOptions: networkLogOptions,
  );

  /// Configures global error handling for Flutter errors.
  ///
  /// This method intercepts Flutter's error reporting mechanisms and logs the errors
  /// to the on-screen logger. It modifies both the `ErrorWidget.builder` and
  /// `FlutterError.onError` to handle errors.
  static void onError() {
    ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
      _onFlutterException(errorDetails);
      return Container();
    };

    FlutterError.onError = _onFlutterException;
  }

  /// Internal method for handling Flutter exceptions and logging them as errors.
  ///
  /// This method is automatically invoked when a Flutter exception occurs
  /// and logs the error details, including the stack trace, to the logger.
  ///
  /// - [errorDetails]: Contains details about the Flutter error.
  static void _onFlutterException(FlutterErrorDetails errorDetails) {
    if (!OnScreenLog.isEnabledFor(LogItemType.error)) return;
    try {
      Timer(
        const Duration(milliseconds: 100),
        () => OnScreenLog.log(
          LogItem(
            type: LogItemType.error,
            title: errorDetails.exception.toString(),
            description: errorDetails.stack != null
                ? errorDetails.stack.toString()
                : '',
          ),
        ),
      );
    } catch (e) {
      debugPrint('cant log error into lexzur debugger: $e');
    }
  }

  /// Logs a custom [LogItem] to the on-screen logger.
  ///
  /// This method can be used to log messages of various types (info, error, success, etc.)
  /// directly to the logger overlay.
  ///
  /// - [logItem]: The log item to be displayed in the logger overlay.
  static void log(LogItem logItem) => OnScreenLog.log(logItem);
}
