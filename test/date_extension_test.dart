import 'package:flutter_onscreen_logger/src/extensions/date_extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats log timestamps without a locale package dependency', () {
    final date = DateTime(2026, 9, 26, 3, 4, 5);

    expect(date.getDateTimeAsLoggingString(), '03:04:05 - 26/09/2026');
  });
}
