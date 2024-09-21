import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

import '../data/log_item_model.dart';

class LogOverlayController extends GetxController {
  final RxBool isExpanded = false.obs;
  final RxList<LogItem> debugItems = <LogItem>[].obs;
  final RxList<bool> debugItemsExpansionState = <bool>[].obs;
  final ScrollController listViewScrollController = ScrollController();

  void toggleOverlay() {
    isExpanded.value = !isExpanded.value;
    if (isExpanded.value) {
      Timer(const Duration(milliseconds: 100), scrollToBottom);
    }
  }

  void toggleItemExpansion(int index) {
    final bool originalValue = debugItemsExpansionState[index];
    debugItemsExpansionState.removeAt(index);
    debugItemsExpansionState.insert(index, !originalValue);
  }

  void generateRandomDebugItems({int numberOfItems = 20}) {
    debugItems.clear();
    for (int i = 0; i < numberOfItems; i++) {
      debugItems.add(LogItem.getRandom());
      debugItemsExpansionState.add(false);
    }
  }

  void copyErrorInfo(LogItem item) {
    Clipboard.setData(
      ClipboardData(
        text:
            'Type: ${item.type.name}\n\n${item.title}\n\n${item.description}\n\n${item.time}',
      ),
    );
    Fluttertoast.showToast(
      msg: 'Log info copied to clipboard!',
      backgroundColor: Colors.white,
      textColor: Colors.black,
    );
  }

  void log(LogItem item) {
    debugItems.add(item);
    debugItemsExpansionState.add(false);
    scrollToBottom();
  }

  scrollToBottom() {
    if (listViewScrollController.hasClients) {
      ///a timer has been added here to allow the new item's layout to finish building before scrolling to it's position
      Timer(const Duration(milliseconds: 400), () {
        listViewScrollController.position.animateTo(
          listViewScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.elasticOut,
        );
      });
    }
  }
}
