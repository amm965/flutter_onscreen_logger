import 'package:dio/dio.dart';
import 'package:flutter_onscreen_logger/flutter_onscreen_logger.dart';
import 'package:flutter_onscreen_logger_dio/flutter_onscreen_logger_dio.dart';

void main() {
  OnScreenLog.init(enabled: true);
  createDioClient();
}

Dio createDioClient() {
  final dio = Dio()..interceptors.add(OnScreenLoggerInterceptor());
  return dio;
}
