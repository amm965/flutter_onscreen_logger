import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/log_item_type.dart';
import '../../extensions/log_item_type_extension.dart';
import '../controllers/logger_overlay_controller.dart';
import 'logger_log_list.dart';

/// A widget that provides an on-screen logger overlay with options to view, share, or clear logs.
class LoggerOverlayWidget extends StatelessWidget {
  late final LoggerOverlayController _controller;

  /// Initializes the logger overlay controller using GetX.
  /// If the controller is not registered, it will be created and registered.
  LoggerOverlayWidget({super.key}) {
    if (Get.isRegistered<LoggerOverlayController>()) {
      _controller = Get.find();
    } else {
      _controller = Get.put(LoggerOverlayController());
    }
  }

  /// Builds the main logger overlay widget.
  /// It uses `Obx` to dynamically update the UI based on the controller's state.
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr, // Always LTR as logs are in English.
      child: Obx(
        () => Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLogToggleButton(context),
              // Toggle button for the logger overlay.
              if (_controller.isExpanded.value) _buildLoggerView(context),
              // Logger view.
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the detailed logger view with log entries and action buttons.
  Widget _buildLoggerView(BuildContext hostContext) {
    final hostTheme = Theme.of(hostContext);
    return Expanded(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: hostTheme,
        darkTheme: hostTheme,
        home: Material(
          color: Colors.black,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'OnScreen Logger',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Logger options',
                      icon: Icon(
                        Icons.more_vert,
                        color: hostTheme.colorScheme.primary,
                      ),
                      onSelected: (value) {
                        switch (value) {
                          case 'logging':
                            _controller.toggleLogging();
                          case 'scroll':
                            _controller.toggleAutoScroll();
                          case 'share':
                            _controller.saveAndShareLogItems();
                          case 'clear':
                            _controller.clearAll();
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'logging',
                          child: _menuLabel(
                            _controller.isLoggingPaused.value
                                ? Icons.play_arrow
                                : Icons.pause,
                            _controller.isLoggingPaused.value
                                ? 'Resume logging'
                                : 'Pause logging',
                          ),
                        ),
                        PopupMenuItem(
                          value: 'scroll',
                          child: _menuLabel(
                            _controller.autoScroll.value
                                ? Icons.sync
                                : Icons.sync_disabled,
                            _controller.autoScroll.value
                                ? 'Disable auto-scroll'
                                : 'Enable auto-scroll',
                          ),
                        ),
                        PopupMenuItem(
                          value: 'share',
                          child: _menuLabel(Icons.share, 'Share all'),
                        ),
                        PopupMenuItem(
                          value: 'clear',
                          child: _menuLabel(Icons.delete_outline, 'Clear all'),
                        ),
                      ],
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final type in LogItemType.values)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: FilterChip(
                              label: Text(type.name),
                              avatar: Icon(
                                type.itemIconByType,
                                size: 18,
                                color: _controller.selectedTypes.contains(type)
                                    ? Colors.black
                                    : type.itemColorByType,
                              ),
                              showCheckmark: false,
                              backgroundColor: Colors.black,
                              selectedColor: type.itemColorByType,
                              side: BorderSide(color: type.itemColorByType),
                              labelStyle: TextStyle(
                                color: _controller.selectedTypes.contains(type)
                                    ? Colors.black
                                    : type.itemColorByType,
                              ),
                              selected: _controller.selectedTypes.contains(
                                type,
                              ),
                              onSelected: (_) => _controller.toggleType(type),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(child: LoggerLogList(controller: _controller)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuLabel(IconData icon, String label) => Row(
    children: [
      Icon(icon, size: 20),
      const SizedBox(width: 12),
      Flexible(child: Text(label)),
    ],
  );

  /// Builds the toggle button to expand or collapse the logger overlay.
  Widget _buildLogToggleButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(400),
          bottomLeft: Radius.circular(400),
        ),
        child: GestureDetector(
          onTap: _controller.toggleOverlay, // Toggle overlay state.
          child: Container(
            height: 45,
            width: 45,
            color: Theme.of(context).colorScheme.primary,
            child: const Center(
              child: Icon(
                Icons.list, // Icon for the toggle button.
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
