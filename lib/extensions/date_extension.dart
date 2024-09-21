import 'package:intl/intl.dart';

extension DateExtension on DateTime {
  String getDateTimeAsDebuggingString() =>
      DateFormat('HH:mm:ss - dd/MM/yyyy').format(this);
}
