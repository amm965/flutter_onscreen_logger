import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/log_item_model.dart';
import '../../extensions/date_extension.dart';
import '../../extensions/log_item_type_extension.dart';
import '../controllers/logger_overlay_controller.dart';
import 'http_log_card.dart';

/// Represents a single log item in the logger overlay list.
class LoggerListItem extends StatelessWidget {
  final LoggerOverlayController _controller = Get.find();

  ///item index
  final int index;

  /// Creates a logger list item with the given index.
  LoggerListItem({super.key, required this.index});

  /// Builds the main widget for a single log item.
  /// Displays an expandable container with a header and body.
  @override
  Widget build(BuildContext context) {
    final LogItem currentItem = _controller.logItems[index];
    final Color itemColor = currentItem.type.itemColorByType;
    if (currentItem.httpDetails != null) {
      return Obx(
        () => HttpLogCard(
          item: currentItem,
          index: index,
          expanded: _controller.logItemsExpansionState[index],
          onToggle: () => _controller.toggleItemExpansion(index),
          onCopy: () => _controller.copyErrorInfo(currentItem),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8), // Rounded corners.
          border: Border.all(
            color: itemColor,
          ), // Border color based on log type.
        ),
        child: Column(
          children: [
            _buildHeader(currentItem, itemColor),
            // Header with title and index.
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Obx(
                () => AnimatedCrossFade(
                  crossFadeState: _controller.logItemsExpansionState[index]
                      ? CrossFadeState
                            .showFirst // Expanded state.
                      : CrossFadeState.showSecond, // Collapsed state.
                  duration: const Duration(milliseconds: 200),
                  firstChild: _buildExpandedItemBody(
                    index,
                    currentItem,
                    itemColor,
                  ),
                  secondChild: _buildCollapsedItemBody(
                    index,
                    currentItem,
                    itemColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the header for a log item.
  /// Displays the title and the log item index with a colored badge.
  Widget _buildHeader(LogItem currentItem, Color itemColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: currentItem.title != null
                ? Text(
                    currentItem.title!,
                    style: TextStyle(
                      color: itemColor, // Title color based on log type.
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  )
                : Container(),
          ),
        ),
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(7),
            bottomLeft: Radius.circular(7),
          ),
          child: Container(
            color: itemColor, // Badge background color.
            height: 20,
            width: 20,
            child: Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: Text(
                  (index + 1).toString(), // Display log item index.
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the collapsed view of the log item's body.
  /// Shows a truncated description of the log.
  Widget _buildCollapsedItemBody(
    int index,
    LogItem currentItem,
    Color itemColor,
  ) {
    return GestureDetector(
      onTap: () => _controller.toggleItemExpansion(index), // Toggle expansion.
      child: Text(
        currentItem.description,
        maxLines: 5,
        style: TextStyle(color: itemColor), // Text color based on log type.
      ),
    );
  }

  /// Builds the expanded view of the log item's body.
  /// Shows the full description, timestamp, and a copy icon.
  Widget _buildExpandedItemBody(
    int index,
    LogItem currentItem,
    Color itemColor,
  ) {
    return GestureDetector(
      onTap: () => _controller.toggleItemExpansion(index), // Toggle expansion.
      child: Column(
        children: [
          Text(
            currentItem.description, // Full log description.
            style: TextStyle(color: itemColor),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currentItem.time.getDateTimeAsLoggingString(), // Log timestamp.
                style: TextStyle(color: itemColor),
              ),
              _buildCopyIcon(currentItem), // Copy log info icon.
            ],
          ),
        ],
      ),
    );
  }

  /// Builds a copy icon to copy the log item's details.
  Widget _buildCopyIcon(LogItem currentItem) {
    return GestureDetector(
      onTap: () => _controller.copyErrorInfo(currentItem), // Copy log info.
      child: Icon(
        Icons.copy_rounded,
        color: currentItem.type.itemColorByType,
        // Icon color based on log type.
        size: 20,
      ),
    );
  }
}
