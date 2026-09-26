import 'package:dio/dio.dart';
import 'package:flutter_onscreen_logger_dio/flutter_onscreen_logger_dio.dart';
import 'package:flutter_onscreen_logger_http/flutter_onscreen_logger_http.dart';
import 'package:http/http.dart' as http;

/// Real clients using both connectors; injectable transports keep tests offline.
class DemoNetworkClients {
  DemoNetworkClients({Dio? dio, http.Client? httpClient})
    : dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
            ),
          ),
      httpClient = OnScreenLoggerClient(httpClient ?? http.Client()) {
    this.dio.interceptors.add(OnScreenLoggerInterceptor(logBodies: true));
  }

  final Dio dio;
  final OnScreenLoggerClient httpClient;
  static const _base = 'https://jsonplaceholder.typicode.com';

  Future<String> runDioDemo() async {
    final response = await dio.get<Object>('$_base/posts/1');
    try {
      await dio.get<Object>('$_base/posts/0');
    } on DioException catch (error) {
      if (error.response?.statusCode != 404) rethrow;
      return 'Dio: HTTP ${response.statusCode}, then expected HTTP 404. Check the logs.';
    }
    return 'Dio requests completed. Check the logs.';
  }

  Future<String> runHttpDemo() async {
    final response = await httpClient.get(Uri.parse('$_base/posts/1'));
    final missing = await httpClient.get(Uri.parse('$_base/posts/0'));
    return 'HTTP: ${response.statusCode}, then ${missing.statusCode}. Check the logs.';
  }

  void close() {
    dio.close(force: true);
    httpClient.close();
  }
}
