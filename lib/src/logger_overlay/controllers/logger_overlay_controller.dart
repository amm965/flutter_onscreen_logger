import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/services.dart';
import 'package:flutter_onscreen_logger/src/extensions/date_extension.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/log_item_model.dart';
import '../../data/log_item_type.dart';
import '../../data/network_log_options.dart';

/// Controller for the logging overlay
class LoggerOverlayController extends GetxController {
  /// Controls the visibility of the logger overlay (expanded/collapsed).
  final RxBool isExpanded = false.obs;

  /// List of log items displayed in the logger.
  final RxList<LogItem> logItems = <LogItem>[].obs;

  /// Types included in the view. Filtering never removes stored logs.
  final RxSet<LogItemType> selectedTypes = LogItemType.values.toSet().obs;

  /// Whether new visible messages scroll into view automatically.
  final RxBool autoScroll = true.obs;

  bool _followingLatest = true;
  int _scrollRequest = 0;
  bool _scrollingToLatest = false;

  /// Whether incoming entries are discarded. Existing logs remain available.
  final RxBool isLoggingPaused = false.obs;

  Set<LogItemType> _enabledTypes = Set.unmodifiable(LogItemType.values);

  NetworkLogOptions _networkLogOptions = const NetworkLogOptions();

  /// Network capture settings used by connectors without an explicit override.
  NetworkLogOptions get networkLogOptions => _networkLogOptions;

  /// Immutable capture types, independent of the overlay's visibility filters.
  Set<LogItemType> get enabledTypes => _enabledTypes;

  /// Whether a new entry of [type] will be retained in the session.
  bool isEnabledFor(LogItemType type) =>
      !isLoggingPaused.value && _enabledTypes.contains(type);

  /// Updates capture and scrolling options without clearing existing entries.
  /// Omitted options retain their current values, including menu changes.
  void configure({
    bool? enabled,
    Set<LogItemType>? enabledTypes,
    bool? autoScroll,
    NetworkLogOptions? networkLogOptions,
  }) {
    if (enabledTypes != null) _enabledTypes = Set.unmodifiable(enabledTypes);
    if (enabled != null) isLoggingPaused.value = !enabled;
    if (networkLogOptions != null) {
      _networkLogOptions = networkLogOptions;
    }
    if (autoScroll != null && autoScroll != this.autoScroll.value) {
      this.autoScroll.value = autoScroll;
      if (autoScroll) {
        scrollToBottom(force: true);
      } else {
        _scrollRequest++;
        _scrollingToLatest = false;
      }
    }
  }

  /// Pauses or resumes capturing entries, independently of auto-scroll.
  void toggleLogging() => configure(enabled: isLoggingPaused.value);

  /// Original indices preserve expansion state when filtering.
  List<int> get visibleIndices => [
    for (var i = 0; i < logItems.length; i++)
      if (selectedTypes.contains(logItems[i].type)) i,
  ];

  /// Includes or excludes a message type.
  void toggleType(LogItemType type) {
    if (!selectedTypes.remove(type)) selectedTypes.add(type);
    scrollToBottom();
  }

  /// Enables or disables automatic scrolling.
  void toggleAutoScroll() => configure(autoScroll: !autoScroll.value);

  /// Tracks the expansion state of each log item (expanded/collapsed).
  final RxList<bool> logItemsExpansionState = <bool>[].obs;

  /// Scroll controller for the list view of log items.
  final ScrollController listViewScrollController = ScrollController();

  /// Toggles the visibility of the logger overlay.
  /// Scrolls to the bottom if the overlay is expanded.
  void toggleOverlay() {
    isExpanded.value = !isExpanded.value;
    if (isExpanded.value) {
      scrollToBottom();
    }
  }

  /// Toggles the expansion state of a specific log item.
  /// [index] - The index of the log item in the list.
  void toggleItemExpansion(int index) {
    final bool originalValue = logItemsExpansionState[index];
    logItemsExpansionState.removeAt(index); // Remove the old state.
    logItemsExpansionState.insert(
      index,
      !originalValue,
    ); // Insert the toggled state.
  }

  /// Copies log item details to the clipboard and shows a toast message.
  /// [item] - The log item to copy.
  void copyErrorInfo(LogItem item) {
    Clipboard.setData(
      ClipboardData(
        text:
            'Type: ${item.type.name}\n\n${item.title}\n\n${item.description}\n\n${item.time}',
      ),
    );

    // Show a toast indicating the log info has been copied.
    Fluttertoast.showToast(
      msg: 'Log info copied to clipboard!',
      backgroundColor: Colors.white,
      textColor: Colors.black,
    );
  }

  /// Adds a new log item to the log and scrolls to the bottom.
  /// [item] - The log item to add.
  void log(LogItem item) {
    if (!isEnabledFor(item.type)) return;
    logItemsExpansionState.add(false);
    logItems.add(item);
    if (selectedTypes.contains(item.type)) scrollToBottom();
  }

  /// Tracks user navigation so new logs do not interrupt reading older entries.
  void handleScrollNotification(ScrollNotification notification) {
    if (notification.depth != 0) return;
    if ((notification is ScrollStartNotification &&
            notification.dragDetails != null) ||
        (notification is UserScrollNotification &&
            notification.direction != ScrollDirection.idle)) {
      _scrollRequest++;
      _scrollingToLatest = false;
    }
    if (!_scrollingToLatest) {
      _followingLatest = notification.metrics.extentAfter <= 1;
    }
  }

  /// Scrolls to the latest entry after layout. [force] ignores auto-scroll.
  /// Repeats after layout to account for lazily measured, variable-height rows.
  void scrollToBottom({bool force = false}) {
    if (!isExpanded.value ||
        (!force && (!autoScroll.value || !_followingLatest))) {
      return;
    }
    final request = ++_scrollRequest;
    _scrollingToLatest = true;
    void jumpAfterLayout() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (request != _scrollRequest) return;
        if (isClosed ||
            !isExpanded.value ||
            (!force && !autoScroll.value) ||
            !listViewScrollController.hasClients) {
          _scrollingToLatest = false;
          return;
        }
        final position = listViewScrollController.position;
        if (position.extentAfter > 1) {
          listViewScrollController.jumpTo(position.maxScrollExtent);
          jumpAfterLayout();
        } else {
          _scrollingToLatest = false;
          _followingLatest = true;
        }
      });
      WidgetsBinding.instance.ensureVisualUpdate();
    }

    jumpAfterLayout();
  }

  /// Clears stored entries and their expansion state.
  void clearAll() {
    _scrollRequest++;
    _scrollingToLatest = false;
    _followingLatest = true;
    logItems.clear();
    logItemsExpansionState.clear();
  }

  @override
  void onClose() {
    listViewScrollController.dispose();
    super.onClose();
  }

  /// Saves the current log items to a file and shares them.
  Future<void> saveAndShareLogItems() async {
    try {
      String content = _saveLogItems(); // Prepare the log content.
      await _shareLogItems(fileContent: content); // Share the log file.
    } catch (e) {
      debugPrint('Error saving or sharing log items: $e');
    }
  }

  /// Creates a file with the log items' content and shares it.
  /// [fileContent] - The content to write to the file.
  Future<void> _shareLogItems({required String fileContent}) async {
    final tempDir = await getTemporaryDirectory(); // Get the temp directory.
    final filePath =
        '${tempDir.path}/log_report.txt'; // File path for the report.
    final file = File(filePath);

    await file.writeAsString(fileContent); // Write content to the file.

    if (await file.exists()) {
      await SharePlus.instance.share(
        ShareParams(files: [XFile(filePath)], text: "Here's the log report!"),
      );
    }
  }

  /// Prepares a string representation of all log items to be saved and shared.
  String _saveLogItems() {
    final shareDate = DateTime.now()
        .getDateTimeAsLoggingString(); // Get current date.

    String content = '';
    content += 'Date of Sharing: $shareDate\n'; // Add date to content.
    content +=
        '\n-------------------------------------------------------------------------------\n\n';

    // Format log items as strings and join them together.
    content += logItems
        .map((item) {
          return """
Type: ${item.type.toString().split('.').last}\n
Title: ${item.title}\n
${item.description}\n
Time: ${item.time.getDateTimeAsLoggingString()}\n
-------------------------------------------------------------------------------
          """;
        })
        .join('\n');
    return content;
  }
}
