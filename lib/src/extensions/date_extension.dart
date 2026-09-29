///Provides extension methods on DateTime
extension DateExtension on DateTime {
  ///formats the date time used for the log items into the following format HH:mm:ss - dd/MM/yyyy
  String getDateTimeAsLoggingString() {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${twoDigits(hour)}:${twoDigits(minute)}:${twoDigits(second)} - '
        '${twoDigits(day)}/${twoDigits(month)}/${year.toString().padLeft(4, '0')}';
  }
}
