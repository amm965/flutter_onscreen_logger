import 'package:get/get.dart';

import 'log_item_model.dart';
import 'log_item_type.dart';

class APIRequestLoggerModel {
  final ApiRequestType requestType;
  final String url;
  final String headers;
  final String? body;

  APIRequestLoggerModel({
    required this.requestType,
    required this.url,
    required this.headers,
    this.body,
  });

  LogItem get debugItem => LogItem(
        type: LogItemType.info,
        title: '${requestType.name.capitalize} API Request',
        description: '''
* URL Called: $url
\n* Headers: $headers
\n* Body: $body
        ''',
      );
}

enum ApiRequestType {
  get,
  post,
  delete,
  update,
}
