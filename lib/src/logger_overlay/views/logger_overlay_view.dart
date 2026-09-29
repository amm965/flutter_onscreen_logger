import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/log_item_type.dart';
import '../../extensions/log_item_type_extension.dart';
import '../controllers/logger_overlay_controller.dart';
import 'logger_log_list.dart';

/// A widget that provides an on-screen logger overlay with options to view, share, or clear logs.
///
/// Place this in the host app's `builder` to inherit its active [Theme], including
/// runtime changes. This works with both [MaterialApp] and `GetMaterialApp`.
class LoggerOverlayWidget extends StatelessWidget {
  static final _filterTheme = ThemeData(
    useMaterial3: true,
    visualDensity: VisualDensity.standard,
    chipTheme: const ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
    ),
  );

  late final LoggerOverlayController _controller;

  /// An optional theme override for the overlay controls and options menu.
  ///
  /// Defaults to [Theme.of] this widget's context. If the overlay is outside the
  /// app's themed subtree, pass the active theme and update it when the app's
  /// theme changes. Log cards retain their message type colors.
  final ThemeData? theme;

  /// Initializes the logger overlay controller using GetX.
  /// If the controller is not registered, it will be created and registered.
  LoggerOverlayWidget({super.key, this.theme}) {
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
    final effectiveTheme = theme ?? Theme.of(context);
    return Directionality(
      textDirection: TextDirection.ltr, // Always LTR as logs are in English.
      child: Obx(
        () => Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLogToggleButton(effectiveTheme),
              // Toggle button for the logger overlay.
              if (_controller.isExpanded.value)
                _buildLoggerView(effectiveTheme),
              // Logger view.
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the detailed logger view with log entries and action buttons.
  Widget _buildLoggerView(ThemeData effectiveTheme) {
    return Expanded(
      // Keep a local navigator for popup menus when mounted in an app builder,
      // which places the logger above the host navigator.
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: effectiveTheme,
        // The host has already resolved brightness and animated theme changes.
        themeMode: ThemeMode.light,
        themeAnimationStyle: AnimationStyle.noAnimation,
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
                    _buildOptionsMenu(),
                  ],
                ),
                // Isolate both ThemeData defaults and explicit ancestor
                // ChipTheme overrides from the filters' diagnostic styling.
                Theme(
                  data: _filterTheme,
                  child: ChipTheme(
                    data: _filterTheme.chipTheme,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final type in LogItemType.values)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: FilterChip(
                                  label: Text(type.name),
                                  avatar: Icon(
                                    type.itemIconByType,
                                    size: 18,
                                    color:
                                        _controller.selectedTypes.contains(type)
                                        ? Colors.black
                                        : type.itemColorByType,
                                  ),
                                  showCheckmark: false,
                                  backgroundColor: Colors.black,
                                  selectedColor: type.itemColorByType,
                                  side: BorderSide(color: type.itemColorByType),
                                  labelStyle: TextStyle(
                                    color:
                                        _controller.selectedTypes.contains(type)
                                        ? Colors.black
                                        : type.itemColorByType,
                                  ),
                                  selected: _controller.selectedTypes.contains(
                                    type,
                                  ),
                                  onSelected: (_) =>
                                      _controller.toggleType(type),
                                ),
                              ),
                          ],
                        ),
                      ),
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

  PopupMenuButton<String> _buildOptionsMenu() {
    return PopupMenuButton<String>(
      tooltip: 'Logger options',
      icon: const Icon(Icons.more_vert, color: Colors.white),
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
            _controller.isLoggingPaused.value ? Icons.play_arrow : Icons.pause,
            _controller.isLoggingPaused.value
                ? 'Resume logging'
                : 'Pause logging',
          ),
        ),
        PopupMenuItem(
          value: 'scroll',
          child: _menuLabel(
            _controller.autoScroll.value ? Icons.sync : Icons.sync_disabled,
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
  Widget _buildLogToggleButton(ThemeData effectiveTheme) {
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
            color: effectiveTheme.primaryColor,
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
