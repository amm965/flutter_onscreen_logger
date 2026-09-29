import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';

import '../controllers/logger_overlay_controller.dart';
import 'logger_list_item.dart';

/// A lazy log list with a viewport-aware count and jump-to-latest control.
class LoggerLogList extends StatefulWidget {
  /// Creates the list for the shared logger session.
  const LoggerLogList({super.key, required this.controller});

  /// The controller holding the session and scroll preferences.
  final LoggerOverlayController controller;

  @override
  State<LoggerLogList> createState() => _LoggerLogListState();
}

class _LoggerLogListState extends State<LoggerLogList> {
  final _viewportKey = GlobalKey();
  final _sliverKey = GlobalKey();
  int _messagesBelow = 0;
  int _itemCount = 0;
  bool _showJump = false;
  bool _updatePending = false;

  void _scheduleCount() {
    if (_updatePending) return;
    _updatePending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updatePending = false;
      if (!mounted) return;
      final scroll = widget.controller.listViewScrollController;
      final viewport = _viewportKey.currentContext?.findRenderObject();
      final sliver = _sliverKey.currentContext?.findRenderObject();
      var lastVisible = -1;
      if (viewport is RenderBox &&
          viewport.hasSize &&
          sliver is RenderSliverList) {
        sliver.visitChildren((child) {
          if (child is! RenderBox || !child.hasSize) return;
          final top = child.localToGlobal(Offset.zero, ancestor: viewport).dy;
          if (top < viewport.size.height && top + child.size.height > 0) {
            final index =
                (child.parentData! as SliverMultiBoxAdaptorParentData).index!;
            if (index > lastVisible) lastVisible = index;
          }
        });
      }
      final total = _itemCount;
      final show =
          total > 0 && scroll.hasClients && scroll.position.extentAfter > 1;
      final below = show && lastVisible >= 0 ? total - lastVisible - 1 : 0;
      if (show != _showJump || below != _messagesBelow) {
        setState(() {
          _showJump = show;
          _messagesBelow = below;
        });
      }
    });
  }

  @override
  Widget build(
    BuildContext context,
  ) => NotificationListener<ScrollMetricsNotification>(
    onNotification: (_) {
      _scheduleCount();
      return false;
    },
    child: NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        widget.controller.handleScrollNotification(notification);
        _scheduleCount();
        return false;
      },
      child: NotificationListener<SizeChangedLayoutNotification>(
        onNotification: (_) {
          _scheduleCount();
          return false;
        },
        child: Stack(
          children: [
            SizedBox.expand(
              key: _viewportKey,
              child: Obx(() {
                final indices = widget.controller.visibleIndices;
                _itemCount = indices.length;
                _scheduleCount();
                if (indices.isEmpty) {
                  return const Center(
                    child: Text(
                      'No matching logs',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }
                return CustomScrollView(
                  controller: widget.controller.listViewScrollController,
                  slivers: [
                    SliverList(
                      key: _sliverKey,
                      delegate: SliverChildBuilderDelegate(
                        (_, index) => SizeChangedLayoutNotifier(
                          key: ObjectKey(
                            widget.controller.logItems[indices[index]],
                          ),
                          child: LoggerListItem(index: indices[index]),
                        ),
                        childCount: indices.length,
                      ),
                    ),
                  ],
                );
              }),
            ),
            if (_showJump)
              Positioned(
                right: 12,
                bottom: 12,
                child: Tooltip(
                  message: 'Jump to latest ($_messagesBelow messages below)',
                  child: FloatingActionButton.small(
                    heroTag: null,
                    onPressed: () =>
                        widget.controller.scrollToBottom(force: true),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.keyboard_double_arrow_down, size: 18),
                        SizedBox(
                          width: 32,
                          height: 12,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '$_messagesBelow',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
