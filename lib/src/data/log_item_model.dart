import 'log_item_type.dart';
import 'http_log_details.dart';

/// Represents a single log item in the logger.
class LogItem {
  /// The type of the log (info, success, warning, error).
  final LogItemType type;

  /// An optional title for the log item.
  final String? title;

  /// The main content/description of the log.
  final String description;

  /// Optional structured network details for the specialized HTTP card.
  final HttpLogDetails? httpDetails;

  /// The timestamp when the log item is created.
  late final DateTime time;

  /// Creates a plain-text log entry. Use [LogItem.network] for network details.
  LogItem({required this.type, this.title, required this.description})
    : httpDetails = null {
    time = DateTime.now();
  }

  /// Creates a network entry with consistent visual and plain-text information.
  LogItem.network({required this.type, required HttpLogDetails details})
    : httpDetails = details,
      title = '${details.method} ${details.url}',
      description = details.toPlainText() {
    time = DateTime.now();
  }
}
