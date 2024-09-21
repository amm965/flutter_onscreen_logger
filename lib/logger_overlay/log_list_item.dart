import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:onscreen_logger/extensions/date_extension.dart';
import 'package:onscreen_logger/extensions/log_item_type_extension.dart';
import 'package:onscreen_logger/logger_overlay/logger_icon.dart';

import '../data/log_item_model.dart';
import 'log_overlay_controller.dart';

class LogListItem extends StatelessWidget {
  final LogOverlayController controller = Get.find();
  final int index;

  LogListItem({
    super.key,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final LogItem currentItem = controller.debugItems[index];
    final Color itemColor = currentItem.type.itemColorByType;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: itemColor,
          ),
        ),
        child: Column(
          children: [
            _buildHeader(currentItem, itemColor),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Obx(
                () => AnimatedCrossFade(
                  crossFadeState: controller.debugItemsExpansionState[index]
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  duration: const Duration(milliseconds: 200),
                  firstChild:
                      _buildExpandedItemBody(index, currentItem, itemColor),
                  secondChild:
                      _buildCollapsedItemBody(index, currentItem, itemColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(LogItem currentItem, Color itemColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              currentItem.title,
              style: TextStyle(
                color: itemColor,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ),
        ),
        Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(7),
                bottomLeft: Radius.circular(7),
              ),
              child: Container(
                color: itemColor,
                height: 20,
                width: 20,
                child: Center(
                  child: Text(
                    (index + 1).toString(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildCollapsedItemBody(
      int index, LogItem currentItem, Color itemColor) {
    return GestureDetector(
      onTap: () => controller.toggleItemExpansion(index),
      child: Text(
        currentItem.description,
        maxLines: 5,
        style: TextStyle(color: itemColor),
      ),
    );
  }

  Widget _buildExpandedItemBody(
      int index, LogItem currentItem, Color itemColor) {
    return GestureDetector(
      onTap: () => controller.toggleItemExpansion(index),
      child: Column(
        children: [
          Text(
            currentItem.description,
            style: TextStyle(color: itemColor),
          ),
          const SizedBox(
            height: 16,
          ),
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currentItem.time.getDateTimeAsDebuggingString(),
                style: TextStyle(
                  color: itemColor,
                ),
              ),
              _buildCopyIcon(currentItem)
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCopyIcon(LogItem currentItem) {
    return GestureDetector(
      onTap: () => controller.copyErrorInfo(currentItem),
      child: LoggerIcon(
        assetPath: 'assets/ic_copy.svg',
        height: 20,
        width: 20,
        color: currentItem.type.itemColorByType,
      ),
    );
  }
}
