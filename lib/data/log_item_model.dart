import 'dart:math';

import 'package:word_generator/word_generator.dart';

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

  static getRandom() {
    final wordGenerator = WordGenerator();

    Random random = Random();
    return LogItem(
      type: LogItemType.values[random.nextInt(LogItemType.values.length)],
      title: wordGenerator.randomSentence(random.nextInt(5) + 5),
      description: wordGenerator.randomSentence(random.nextInt(50) + 50),
    );
  }
}
