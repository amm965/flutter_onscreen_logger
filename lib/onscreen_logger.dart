import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_onscreen_logger/extensions/dio_exception_logger_extension.dart';

import 'data/api_request_logger_model.dart';
import 'data/log_item_model.dart';
import 'data/log_item_type.dart';
import 'logger_overlay/logger_overlay_controller.dart';

class OnscreenLogger {
  OnscreenLogger._();

  static void init() {
    Get.put(LoggerOverlayController());
  }

  static void onError() {
    ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
      _onFlutterException(errorDetails);
      return Container();
    };

    FlutterError.onError = _onFlutterException;
  }

  static void _onFlutterException(FlutterErrorDetails errorDetails) {
    try {
      final LoggerOverlayController debugController = Get.find();
      Timer(
        const Duration(milliseconds: 100),
        () => debugController.log(
          LogItem(
            type: LogItemType.error,
            title: errorDetails.exception.toString(),
            description:
                errorDetails.stack != null ? errorDetails.stack.toString() : '',
          ),
        ),
      );
    } catch (e) {
      debugPrint('cant log error into lexzur debugger: $e');
    }
  }

  static void logDioException(DioException dioException) {
    final LoggerOverlayController debugController = Get.find();
    debugController.log(dioException.getDebugItem());
  }

  static void logPreHttpRequestInfo(
      APIRequestLoggerModel apiRequestLoggerModel) {
    final LoggerOverlayController debugController = Get.find();
    debugController.log(apiRequestLoggerModel.debugItem);
  }

  static void log(LogItem debugItem) {
    final LoggerOverlayController debugController = Get.find();
    debugController.log(debugItem);
  }
}
