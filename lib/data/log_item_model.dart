import 'log_item_type.dart';

class LogItem {
  final LogItemType type;
  final String title, description;
  late final DateTime time;

  LogItem({
    required this.type,
    required this.title,
    required this.description,
  }) {
    time = DateTime.now();
  }
}
