import 'package:flutter/material.dart';

import '../../data/http_log_details.dart';
import '../../data/log_item_model.dart';
import '../../extensions/date_extension.dart';
import '../../extensions/log_item_type_extension.dart';

/// A compact network summary with expandable, selectable request details.
class HttpLogCard extends StatelessWidget {
  /// Creates a card for an entry with non-null structured HTTP details.
  const HttpLogCard({
    super.key,
    required this.item,
    required this.index,
    required this.expanded,
    required this.onToggle,
    required this.onCopy,
  });

  /// Network entry, including its type, timestamp, and captured details.
  final LogItem item;

  /// Position in the full session, unaffected by type filters.
  final int index;

  /// Whether to show the full URL, failure, and body sections.
  final bool expanded;

  /// Expands or collapses the card without changing the captured entry.
  final VoidCallback onToggle;

  /// Copies the complete text representation, including captured details.
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final details = item.httpDetails!;
    final color = item.type.itemColorByType;
    final uri = Uri.tryParse(details.url);
    final path = uri == null || uri.path.isEmpty ? '/' : uri.path;
    final phase = switch (details.phase) {
      HttpLogPhase.request => 'Request',
      HttpLogPhase.response => 'Response',
      HttpLogPhase.error => 'Failed',
    };
    final phaseIcon = switch (details.phase) {
      HttpLogPhase.request => Icons.north_east,
      HttpLogPhase.response => Icons.south_west,
      HttpLogPhase.error => Icons.error_outline,
    };
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: const Color(0xFF11151C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withValues(alpha: 0.65)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              button: true,
              expanded: expanded,
              label: '$phase ${details.method} $path',
              child: InkWell(
                onTap: onToggle,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                _badge(
                                  details.method.toUpperCase(),
                                  const Color(0xFF8ABEFF),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(phaseIcon, size: 15, color: color),
                                    const SizedBox(width: 4),
                                    Text(
                                      phase,
                                      style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                if (details.statusCode != null)
                                  _badge('HTTP ${details.statusCode}', color),
                                if (details.duration != null)
                                  Text(
                                    '${details.duration!.inMilliseconds} ms',
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            expanded ? Icons.expand_less : Icons.expand_more,
                            color: Colors.white60,
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        path,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        uri?.authority.isNotEmpty == true
                            ? uri!.authority
                            : details.url,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          if (details.requestId != null)
                            Text(
                              '#${details.requestId}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontFamily: 'monospace',
                                fontSize: 11,
                              ),
                            ),
                          Text(
                            item.time.getDateTimeAsLoggingString(),
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            'Entry ${index + 1}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (expanded) ...[
              const Divider(height: 1, color: Color(0xFF303640)),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _section(
                      'URL',
                      SelectableText(
                        details.url,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (details.error != null)
                      _section(
                        'FAILURE',
                        SelectableText(
                          details.error!,
                          style: TextStyle(color: color, fontSize: 13),
                        ),
                      ),
                    _section(
                      details.phase == HttpLogPhase.request
                          ? 'REQUEST BODY'
                          : 'RESPONSE BODY',
                      details.body == null
                          ? const Text(
                              'Body not captured',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF090C11),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxHeight: 260,
                                ),
                                child: SingleChildScrollView(
                                  primary: false,
                                  child: SingleChildScrollView(
                                    primary: false,
                                    scrollDirection: Axis.horizontal,
                                    child: SelectableText(
                                      details.body!.isEmpty
                                          ? '(empty)'
                                          : details.body!,
                                      style: const TextStyle(
                                        color: Color(0xFFD5E4F7),
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: onCopy,
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('Copy log'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.13),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11),
    ),
  );

  Widget _section(String title, Widget content) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white54,
            fontWeight: FontWeight.w700,
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 7),
        content,
      ],
    ),
  );
}
