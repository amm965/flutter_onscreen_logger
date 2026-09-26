import 'package:flutter_onscreen_logger/flutter_onscreen_logger.dart';
import 'package:flutter_onscreen_logger_http/flutter_onscreen_logger_http.dart';
import 'package:http/http.dart' as http;

void main() {
  OnScreenLog.init(enabled: true);
  createHttpClient();
}

OnScreenLoggerClient createHttpClient() {
  final client = OnScreenLoggerClient(http.Client());
  return client;
}
