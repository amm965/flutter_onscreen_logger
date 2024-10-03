import 'package:flutter/material.dart';
import 'package:flutter_onscreen_logger/src/logger_overlay/views/logger_icon.dart';
import 'package:get/get.dart';

import 'logger_list_item.dart';
import '../controllers/logger_overlay_controller.dart';

class LoggerOverlayWidget extends StatelessWidget {
  final LoggerOverlayController controller = Get.find();

  LoggerOverlayWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,

      /// this layout should only use ltr regardless of the app lang, since it only show logs in english
      child: Obx(
        () => Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDebugToggleButton(),
              if (controller.isExpanded.value) _buildLoggerView(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoggerView() {
    return Expanded(
      child: Container(
        color: Colors.black,
        child: SafeArea(
          child: Column(
            children: [
              const Text(
                'OnScreen Logger',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(
                height: 4,
              ),
              Expanded(
                child: ListView.builder(
                    controller: controller.listViewScrollController,
                    itemCount: controller.debugItems.length,
                    itemBuilder: (BuildContext context, int index) {
                      return LoggerListItem(
                        index: index,
                      );
                    }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDebugToggleButton() {
    return Padding(
      padding: const EdgeInsets.only(
        left: 8,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(400),
          bottomLeft: Radius.circular(400),
        ),
        child: GestureDetector(
          onTap: controller.toggleOverlay,
          child: Container(
            height: 40,
            width: 40,
            color: Get.theme.primaryColor,
            child: const Center(
              child: LoggerIcon(
                assetPath:
                    'packages/flutter_onscreen_logger/lib/assets/ic_logs.svg',
                color: Colors.white,
                height: 16,
                width: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
